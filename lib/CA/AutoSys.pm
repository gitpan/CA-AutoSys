#
# $Id: AutoSys.pm 3 2007-01-04 00:21:24Z sini $
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

package CA::AutoSys;

require CA::AutoSys::Job;
require CA::AutoSys::Status;

use strict;
use warnings;
use DBI;

use vars qw($VERSION);

$VERSION = '0.99';

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(&new);

sub new {
	my $self = {};
	my $class = shift();

	if (@_) {
		my %args = @_;
		$self->{server} = $args{server} ? $args{server} : undef;
		$self->{user} = $args{user} ? $args{user} : undef;
		$self->{password} = $args{password} ? $args{password} : undef;
	}

	if (!defined($self->{server})) {
		die("missing server name in new()");
	}

	$self->{dbh} = DBI->connect("dbi:Sybase:server=$self->{server}", $self->{user}, $self->{password});
	if (!$self->{dbh}) {
		die("can't connect to server $self->{server}: ".$DBI::errstr);
	}

	bless($self);
	return $self;
}	# new()

sub find_jobs {
	my $self = shift();
	my $job_name = shift();
	my $sth = $self->{dbh}->prepare(qq{
		select	j.job_name, j.job_type, j.joid, s.last_start, s.last_end, s.status, s.run_num, s.ntry, s.exit_code
		from	job j join job_status s
		on		j.joid = s.joid
		where	j.job_name like '$job_name'
		order by j.joid
	});
	$sth->execute() or die("can't select info for job $job_name: ".$sth->errstr());
	return CA::AutoSys::Job->new(database_handle => $self->{dbh}, statement_handle => $sth);
}	# find_jobs()

sub send_event {
	my $self = shift();
	my ($job_name, $event, $status, $event_time);
	if (@_) {
		my %args = @_;
		$job_name = $args{job_name} ? $args{job_name} : '';
		$event = $args{event} ? $args{event} : '';
		$status = $args{status} ? $args{status} : '';
		$event_time = $args{event_time} ? $args{event_time} : '';
	}

	my $sth = $self->{dbh}->prepare(qq{
	exec sendevent '$event', '$job_name', '$status', '', '$event_time', ''
	});

	$sth->execute();

	my ($rc) = $sth->fetchrow_array();
	return $rc;
}	# send_event()

1;
