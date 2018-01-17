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

=cut

package EnsEMBL::REST::Controller::Lookup;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN { extends 'EnsEMBL::REST::Base::Controller' }

with 'EnsEMBL::REST::Role::PostLimiter';

my $FORMAT_TYPES = { full => 1, condensed => 1 };

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(
  compliance_mode => 1,

  'default' => 'application/json',
  'map' => {
    'application/json' => 'JSON',
    'application/x-yaml'        => 'YAML',
  },
);

#
# Do any initialization here, such as pre-loading caches.
# As well load any configuration files, any returned value
# will be placed in (EnsEMBL::REST->config()->{"Controller::Lookup"}
#
sub initialize_controller {
    return;
}


sub endpoint_documentation {
    my $endpoints = {
	'Lookup' => {
	    'lookup_id' => {
		'method'      => 'GET',
		'uri'         => 'lookup/id/:id',
		'description' => 'Uses the given identifier to return the archived sequence',
	    }
	}
    };

    return $endpoints;
}

sub endpoints {
    my $endpoints = {
	'lookup_id' => {
		'method'      => 'GET',
		'endpoint'    => 'lookup/id/:id',
		'section'     => 'Lookup',
	    }
    };

    return $endpoints;
}


sub id : Chained('') PathPart('lookup/id') ActionClass('REST') {
  my ($self, $c, $id) = @_;

  # output format check
  my $format = $c->request->param('format') || 'full';
  $c->go('ReturnError', 'custom', [qq{The format '$format' is not an understood encoding}]) unless $FORMAT_TYPES->{$format};

}

sub id_GET {
  my ($self, $c, $id) = @_;
  unless (defined $id) { $c->go('ReturnError', 'custom', [qq{Id must be provided as part of the URL.}])}
  my $features;
  try {
    $features = $c->model('Lookup')->find_and_locate_object($id);
    $c->go('ReturnError', 'custom',  [qq{No valid lookup found for ID $id}]) unless $features->{species};
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->status_ok( $c, entity => $features);
}

sub id_POST {
  my ($self, $c) = @_;
  my $post_data = $c->req->data;
  my $id_list = $post_data->{'ids'};
  $self->assert_post_size($c,$id_list);
  $self->_include_user_params($c,$post_data);
  my $feature_hash;
  try {
    $feature_hash = $c->model('Lookup')->find_and_locate_list($id_list);
  };

  $self->status_ok( $c, entity => $feature_hash);
}
