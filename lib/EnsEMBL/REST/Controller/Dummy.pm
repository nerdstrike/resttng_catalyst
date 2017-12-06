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

package EnsEMBL::REST::Controller::Dummy;

use Moose;
use namespace::autoclean;
use Data::Dumper;

#BEGIN { extends 'Catalyst::Controller::REST' }
BEGIN { extends 'EnsEMBL::REST::Base::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(
#  namespace => '',
  compliance_mode => 1,

  'default' => 'application/json',
  'map' => {
    'application/json' => 'JSON',
    'text/html'        => 'JSON',
    'shitty/type'      => 'JSON',
  },
);

sub index2 : Path('dummy') ActionClass('REST') {
  my ( $self, $c ) = @_;
  print "HERE, dummy controller dispatch\n";

  return;
}

sub index2_GET {
  my ($self, $c) = @_;

  print "dummy controller GET\n";
#  $c->go('EnsEMBL::REST::Controller::Documentation','index');

  print STDERR Dumper($c->request->accepted_content_types);

  $self->status_ok(
      $c,
      entity => { foo => 'bar' });

}

sub index2_POST {
  my ($self, $c) = @_;

  print "dummy controller POST\n";
  my $post_data = $c->req->data;
  print STDERR Dumper($post_data);
  $c->go('EnsEMBL::REST::Controller::Documentation','index');

}


sub initialize_controller {
    return;
}

sub endpoint_documentation {
    return;
}

sub endpoints {
    return;
}

=head2 end

Attempt to render a view, if needed.

=cut

#sub end : ActionClass('Serialize') {}

__PACKAGE__->meta->make_immutable;



1;
