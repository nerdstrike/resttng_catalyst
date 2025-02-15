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

package EnsEMBL::REST::View::OrthoXML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';
with 'EnsEMBL::REST::Role::Tree';

sub process {
  my ($self, $c, $stash_key) = @_;
  $c->res->body(${$self->encode_orthoxml($c, $stash_key)});
  $self->set_content_disposition($c, 'xml', $stash_key);
  $c->res->headers->header('Content-Type' => 'text/x-orthoxml+xml');
  return 1;
}


__PACKAGE__->meta->make_immutable;

1;
