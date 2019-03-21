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

=cut

package EnsEMBL::REST::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'EnsEMBL::REST::Base::Controller' }

#
# Sets the default content type for the root controller ("/")
# to text/html via the tt template engine. But allows JSON
# if requested via the Accept header.
#
__PACKAGE__->config(
  namespace => '',
  compliance_mode => 1,

  'default' => 'text/html',
  'map' => {
    'text/html'        => 'View',
    'application/json' => 'JSON',
  },
);

sub index : Path : Args(0) {
  my ( $self, $c ) = @_;
  $c->log->debug("HERE, default index path";
  $c->go('EnsEMBL::REST::Controller::Documentation','index');
}

=head2 default

Standard 404 error page

=cut

#sub default : Path {
#  my ( $self, $c ) = @_;

#  print "In default path\n";
#  my $url = $c->uri_for('/');
#  $c->go( 'ReturnError', 'not_found', [qq{page not found. Please check your uri and refer to our documentation $url}] );
#}

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

#sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;



1;
