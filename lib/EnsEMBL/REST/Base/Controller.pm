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

EnsEMBL::REST::Base::Controller - Base controller that all EnsEMBL::REST controllers should inherit from

=head1 AUTHOR

The EnsEMBL Group - http://www.ensembl.org/Help/Contact

=head1 SYNOPSIS

The root controller for all controllers in the Ensembl REST server

=head1 DESCRIPTION

A base controller for REST controllers that can auto-load configuration and such from the PERL5LIB

=cut

package EnsEMBL::REST::Base::Controller;
use Moose;
use Carp;
use Config::Any::Merge;
use File::Basename;
use File::Spec;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
  compliance_mode => 1,
);

# Default null initialization function if a controller doesn't implement one

sub initialize_controller {
    ...
}

# Default null endpoint documentation function if a controller doesn't implement one

sub endpoint_documentation {
    ...
}

# Default null endpoints list function if a controller doesn't implement one

sub endpoints {
    ...
}

# Attempt to load the configuration from a few well known locations.
# In order:
# <path to derived package base dir>/derived_package_name.conf
# <path to derived package base dir>/etc/derived_package_name.conf
# <EnsEMBL::REST:Base::Controller base dir>/derived_package_name.conf
# <EnsEMBL::REST:Base::Controller base dir>/etc/derived_package_name.conf
#
# Settings from later configs in the list will not overwrite earlier ones.
#
# Example for EnsEMBL::REST:Base::Controller:
# <dir where Controller.pm lives>/../../../../ensembl_rest_base_controller.conf

sub _load_config {
    my $self = shift;

    # Find the package name and file location of derived class
    my ($package, $derived_pkg_filename, $line) = caller;

    # Get the directory where derived class lives
    my ($derived_pkg_base, $derived_pkg_stem) = $self->_package_base_dir($package, $derived_pkg_filename);
    # Get the directory where EnsEMBL::REST:Base::Controller lives
    my ($my_pkg_base, $my_pkg_stem) = $self->_package_base_dir(__PACKAGE__, __FILE__);

    # Build stems to search
    my @stems;
    push @stems, "$derived_pkg_base$derived_pkg_stem", $derived_pkg_base . "etc/$derived_pkg_stem";
    push @stems, "$my_pkg_base$my_pkg_stem", $my_pkg_base . "etc/$my_pkg_stem";

    # Hunt through the stems in order looking for config files
    $self->{config} = Config::Any::Merge->load_stems({stems => \@stems, override => 0 });

}

# Helper to fetch the base directory and flattened package name
# for a given package and it's corresponding file

sub _package_base_dir {
    my ($self, $package, $package_file) = @_;

    my($filename, $dirs, $suffix) = fileparse($package_file);
    my $levels_up = $package =~ s/::/_/g;
    $levels_up++; # We should be in the lib or modules directory, one more please
    my $package_base = $dirs . "../"x$levels_up;

    return $package_base, lc($package);
}

sub end : ActionClass('Serialize') {}

__PACKAGE__->meta->make_immutable;

1;
