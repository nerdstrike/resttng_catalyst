=head1 LICENSE
  
  See the NOTICE file distributed with this work for additional information
  regarding copyright ownership.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

=head1 NAME

EnsEMBL::REST - A RESTful API for the access of data from Ensembl and Ensembl compatible resources

=head1 AUTHOR

The EnsEMBL Group - http://www.ensembl.org/Help/Contact

=cut

package EnsEMBL::REST;

use Moose;
use HTML::Entities;
use URI::Escape qw{ uri_escape_utf8 };
use namespace::autoclean;
use Log::Log4perl::Catalyst;
use EnsEMBL::REST::Types;

use 5.010_001;

extends 'Catalyst';
BEGIN { extends 'Catalyst::Controller::REST' }

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory
#     SubRequest: performs subrequests which we need for the doc pages
#          Cache: Perform in-application caching

  # -Debug
use Catalyst qw/
  ConfigLoader
  Static::Simple
  Cache
/;


our $VERSION = '7.0';

# Configure the application.
#
# Note that settings in ensembl_rest.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
  name => 'EnsEMBL::REST',
  # Disable deprecated behavior needed by old applications
  disable_component_resolution_regex_fallback => 1,

  #Allow key = [val] to become an array
  'Plugin::ConfigLoader' => {
    driver => {
      General => {-ForceArray => 1},
    },
  },
);

# Initialize the controllers
#
# As the final step of initializing the REST server,
# cycle through all the controllers and initialize them.
# This includes initialization, fetching their public facing
# documentation fragments, and a list of all controllers along
# with the allowed responses in JSON Schema.

after setup_finalize => sub {
  my $app = shift;

  __PACKAGE__->log->info("Initializing controllers");
  foreach my $controller ($app->controllers) {
    __PACKAGE__->log->debug("Initializing controller $controller");
    my $cfg_fragment = $app->controller($controller)->initialize_controller();

    # If we've received a configuration fragment and it's a hash,
    # splice it in to our master configuration
    if($cfg_fragment && (ref $cfg_fragment eq 'HASH')) {
      if(EnsEMBL::REST->config()->{"Controller::$controller"}) {
        __PACKAGE__->log->warn("Configuration section Controller::$controller exists, about to overwrite it");
      }

      EnsEMBL::REST->config()->{"Controller::$controller"} = $cfg_fragment;
    }
  }

  __PACKAGE__->log->info("Fetching documentation from controllers");
  foreach my $controller ($app->controllers) {
    __PACKAGE__->log->debug("Fetching documentation from controller $controller");
    my $endpoint_documentation = $app->controller($controller)->endpoint_documentation();

    # DO SOMETHING with the documentation fragment here
    if($endpoint_documentation && (ref($endpoint_documentation) eq 'HASH')) {
      foreach my $section (keys %$endpoint_documentation) {
        if(exists EnsEMBL::REST->config()->{"Documentation"}->{$section}) {
          @{EnsEMBL::REST->config()->{"Documentation"}->{$section}}{keys $endpoint_documentation->{$section}} =
             values $endpoint_documentation->{$section};
        } else {
          EnsEMBL::REST->config()->{"Documentation"}->{$section} = $endpoint_documentation->{$section};
        }
      }
    }
  }

  __PACKAGE__->log->info("Fetching endpoints from controllers");
  foreach my $controller ($app->controllers) {
    __PACKAGE__->log->debug("Fetching endpoints from controller $controller");
    my $endpoints = $app->controller($controller)->endpoints();

    # DO SOMETHING with the endpoints fragment here
    if($endpoints && (ref($endpoints) eq 'HASH')) {
      foreach my $endpoint (keys %$endpoints) {
        if(exists EnsEMBL::REST->config()->{"Endpoints"}->{$endpoint}) {
          print STDERR "WARNING: Endpoint $endpoint is being redefined in Controller $controller\n";
        }
        EnsEMBL::REST->config()->{"Endpoints"}->{$endpoint} = $endpoints->{$endpoint};

      }
    }
  }

};

# Start the application
my $log4perl_conf = $ENV{ENS_REST_LOG4PERL}|| 'log4perl.conf';
if(-f $log4perl_conf) {
  __PACKAGE__->log(Log::Log4perl::Catalyst->new($log4perl_conf));
}
else {
  __PACKAGE__->log(Log::Log4perl::Catalyst->new());
}
__PACKAGE__->setup();

__PACKAGE__->config->{'custom-error-message'}->{'view-name'}         = 'TT';
__PACKAGE__->config->{'custom-error-message'}->{'error-template'}    = 'error.tt';

#HACK but it works
sub turn_on_config_serialisers {
  my ($class, $package) = @_;
  if($class->config->{jsonp}) {
    $package->config(
      map => {
        'text/javascript'     => 'JSONP',
      }
    );
  }

## Only add a default for text/html if it is not already set by the controller
  if(!$package->config->{map}->{'text/html'}) {
#    $package->config(default => 'text/html');
    $package->config(
      map => {
        'text/html' => 'YAML::HTML'
      }
    );
  }

  return;
}


## Intercept default error page
## Page not found is dealt with in Root.pm, this deals with mistyped urls and replaces the default 'Please come back later' page
sub finalize_error {
  my $c = shift;
  my $config = $c->config->{'custom-error-message'};
  
  # in debug mode return the original "page" 
  if ( $c->debug ) {
    $c->maybe::next::method;
    return;
  }
  
  # create error string out of error array
  my $error = join '<br/> ', map { encode_entities($_) } @{ $c->error };
  $error ||= 'No output';

  # render the template
  my $action_name = $c->action->reverse;
  $c->stash->{'finalize_error'} = $action_name.': '.$error;
  $c->response->content_type(
    $config->{'content-type'} || 'text/html; charset=utf-8' );
  my $view_name = $config->{'view-name'} || 'TT';
  eval {
    $c->response->body($c->view($view_name)->render($c,
      $config->{'error-template'} || 'error.tt' ));
  };
  if ($@) {
    $c->log->error($@);
    $c->maybe::next::method;
  }
  
  my $response_status = $config->{'response-status'};
  $response_status = 500 if not defined $response_status;
  $c->response->status($response_status);
}


1;
