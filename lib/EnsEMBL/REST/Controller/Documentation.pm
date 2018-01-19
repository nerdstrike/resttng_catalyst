=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

EnsEMBL::REST::Controller::Documentation

=head1 DESCRIPTION

Prototype of documentation system, browsers will be shown a version
of the documentation based on the templates under root/documentation/

However if a client sends a header such as Accept: Application/JSON, a
programmatically created version will be returned. This is done via the
REST::ForBrowsers ActionClass.

=cut

package EnsEMBL::REST::Controller::Documentation;

use Moose;
use namespace::autoclean;
require EnsEMBL::REST;
use Bio::EnsEMBL::ApiVersion qw/software_version/;

BEGIN { extends 'EnsEMBL::REST::Base::Controller' }

# Configure the default content type as HTML but allow
# JSON so programmatic clients can come in and get
# an endpoint listing straight from our homepage

__PACKAGE__->config(
  compliance_mode => 1,

  'default' => 'text/html',
  'map' => {
    'text/html'        => 'View',
    'application/json' => 'JSON',
  },
);

sub begin : Private {
  my ($self, $c) = @_;

  print STDERR "Making it to Documentation::begin()\n";
#  my $endpoints = $c->model('Documentation')->merged_config($c);
  $c->stash()->{endpoints} = EnsEMBL::REST->config()->{"Endpoints"};
  $c->stash()->{groups} = EnsEMBL::REST->config()->{"Documentation"};
#  my $cfg = EnsEMBL::REST->config();
#  $c->stash(
#    site_name => $cfg->{site_name},
#    service_name => $cfg->{service_name},
#    service_logo => $cfg->{service_logo},
#    service_parent_url => $cfg->{service_parent_url},
#    user_guide => $cfg->{user_guide},
#    service_version => $EnsEMBL::REST::VERSION,
#    ensembl_version => software_version(),
#    copyright_footer => $cfg->{copyright_footer},
#    wiki_url => $cfg->{wiki_url},
#    bootstrap_css => $cfg->{bootstrap_css},
#  );
  return;
}

# Endpoint controller for documentation, uses REST::ForBrowsers
# to dispatch based on the Accept header.

sub index :Path :Args(0) :ActionClass('REST::ForBrowsers') {
  my ($self, $c) = @_;

}

# If we receive a GET method request and ActionClass didn't
# think it was a browser, make a data structure based
# on the documentation configuration and pass it back to
# whichever serializer is configured and appropriate based
# on the Accept header.

sub index_GET : Private {
  my ($self, $c) = @_;

  my $endpoints = $c->config()->{Documentation};
  # Enrich/tune the documentation to...OpenAPI standards?

  if($endpoints) {

      $self->status_ok(
	  $c,
	  entity => $endpoints);

  } else {
      $self->status_not_found(
	  $c,
	  message => "Error, no endpoints found");
  }
}

# The ActionClass thought it was a browser, so we'll let
# the serializer use the root/documentation/index.tt
# template to generate a human readable document.

sub index_GET_html : Private {
  my ($self, $c) = @_;

  return;
}

sub info :Path('info') : Args(1) : ActionClass('REST::ForBrowsers') {
  my ($self, $c, $endpoint) = @_;

}

sub info_GET : Private {
  my ($self, $c, $endpoint) = @_;

  my $endpoint_cfg = $c->config()->{Endpoints}->{$endpoint};
  if($endpoint_cfg) {
    my $section =  $c->config()->{Endpoints}->{$endpoint}->{section};
    $self->status_ok(
	$c,
	entity => $c->config()->{Documentation}->{$section}->{$endpoint});
  } else {
    $self->status_not_found(
	$c,
	message => "Endpoint '${endpoint}' Documentation Cannot Be Found");
  }
}

sub info_GET_html : Private {
  my ($self, $c, $endpoint) = @_;

  print STDERR "$endpoint\n";
  my $endpoint_cfg = $c->config()->{Endpoints}->{$endpoint};
  if($endpoint_cfg) {
      my $section =  $c->config()->{Endpoints}->{$endpoint}->{section};
      $c->stash()->{endpoint} = $c->config()->{Documentation}->{$section}->{$endpoint};
  }
  else {
    $c->response->status(404);
    $c->stash()->{template} = 'documentation/no_info.tt';
    $c->stash()->{template_title} = "Endpoint '${endpoint}' Documentation Cannot Be Found";
  }
  return;
}

1;
