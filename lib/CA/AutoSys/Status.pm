#
# $Id: Status.pm 3 2007-01-04 00:21:24Z sini $
#
# CA::AutoSys - Perl Interface to CA's AutoSys job control.
# Copyright (c) 2006 Susnjar Software Engineering <sini@susnjar.de>
# See LICENSE for terms of distribution.
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

package CA::AutoSys::Status;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.99';

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(&new &format_status &format_time);

our %status_names = (
	0 => '  ',	# *empty*
	1 => 'RU',	# running
	2 => ' 2',	# *not defined*
	3 => 'ST',	# starting
	4 => 'SU',	# success
	5 => 'FA',	# failure
	6 => 'TE',	# terminated
	7 => 'OI',	# on ice
	8 => 'IN',	# inactive
	9 => 'AC',	# activated
	10 => 'RE',	# restart
	11 => 'OH',	# on hold
	12 => 'QW',	# queue wait
	13 => '13',	# *not defined*
	14 => 'RD',	# refresh dependencies
	15 => 'RF',	# refresh filewatcher
);

sub new {
	my $self = {};
	my $class = shift();

	if (@_) {
		my %args = @_;
		$self->{last_start} = $args{last_start} ? $args{last_start} : undef;
		$self->{last_end} = $args{last_end} ? $args{last_end} : undef;
		$self->{status} = $args{status} ? $args{status} : undef;
		$self->{run_num} = $args{run_num} ? $args{run_num} : undef;
		$self->{ntry} = $args{ntry} ? $args{ntry} : undef;
		$self->{exit_code} = $args{exit_code} ? $args{exit_code} : undef;
	}

	bless($self);
	return $self;
}	# new()

sub format_status {
	my $status = shift();
	return $status_names{$status};
}	# format_status()

sub format_time {
	my $time = shift();
	if (!defined($time) || $time == 999999999) {
		return "-----";
	}
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = gmtime($time);
	$mon++;
	$year += 1900;
	return sprintf("%02d/%02d/%04d  %02d:%02d:%02d", $mon, $mday, $year, $hour, $min, $sec);
	# return sprintf("%02d/%02d/%04d  %02d:%02d:%02d (%d)", $mon, $mday, $year, $hour, $min, $sec, $time);
}	# format_time()

1;
