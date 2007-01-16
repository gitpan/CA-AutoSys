#
# $Id: Job.pm 14 2007-01-16 10:02:19Z sini $
#
# CA::AutoSys - Perl Interface to CA's AutoSys job control.
# Copyright (c) 2007 Susnjar Software Engineering <sini@susnjar.de>
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

package CA::AutoSys::Job;

require CA::AutoSys::Status;

use strict;
use warnings;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(&new);

my $debug = 0;

sub new {
	my $self = {};
	my $class = shift();

	if (@_) {
		my %args = @_;
		$self->{dbh} = $args{database_handle} ? $args{database_handle} : undef;
		$self->{sth} = $args{statement_handle} ? $args{statement_handle} : undef;
		$self->{parent_job} = $args{parent_job} ? $args{parent_job} : undef;
	}

	if ($debug) {
		printf("DEBUG: Job(%s) created.\n", $self);
	}

	bless($self);
	return $self;
}	# new()

sub next_job {
	my $self = shift();
	if ($debug) {
		printf("DEBUG: Job(%s): next_job()\n", $self);
	}
	my ($job_name, $job_type, $joid, $last_start, $last_end, $status, $run_num, $ntry, $exit_code);
	if (($job_name, $job_type, $joid, $last_start, $last_end, $status, $run_num, $ntry, $exit_code) = $self->{sth}->fetchrow_array()) {
		$self->{job_name} = $job_name;
		$self->{job_type} = $job_type;
		$self->{joid} = $joid;
		$self->{status} = CA::AutoSys::Status->new(last_start => $last_start, last_end => $last_end, status => $status, run_num => $run_num, ntry => $ntry, exit_code => $exit_code);
		return $self;
	} else {
		$self->{sth}->finish();
		return undef;
	}
}	# next_job()

sub next_child {
	my $self = shift();
	if ($debug) {
		printf("DEBUG: Job(%s): next_child()\n", $self);
	}
	my ($job_name, $job_type, $joid, $last_start, $last_end, $status, $run_num, $ntry, $exit_code);
	if (($job_name, $job_type, $joid, $last_start, $last_end, $status, $run_num, $ntry, $exit_code) = $self->{sth}->fetchrow_array()) {
		$self->{parent_job}->{child_cnt}++;
		$self->{job_name} = $job_name;
		$self->{job_type} = $job_type;
		$self->{joid} = $joid;
		$self->{status} = CA::AutoSys::Status->new(last_start => $last_start, last_end => $last_end, status => $status, run_num => $run_num, ntry => $ntry, exit_code => $exit_code);
		return $self;
	} else {
		$self->{sth}->finish();
		return undef;
	}
}	# next_child()

sub find_children {
	my $self = shift();
	if ($debug) {
		printf("DEBUG: Job(%s): find_children()\n", $self);
	}
	my $sth = $self->{dbh}->prepare(qq{
		select	j.job_name, j.job_type, j.joid, s.last_start, s.last_end, s.status, s.run_num, s.ntry, s.exit_code
		from	job j join job_status s
		on		j.joid = s.joid
		where	j.box_joid = $self->{joid}
		order by j.joid
	});
	if ($debug) {
		printf("DEBUG: Job(%s): selecting children for joid %d\n", $self, $self->{joid});
	}
	$self->{child_cnt} = 0;
	$sth->execute() or die("can't select children for job $self->{job_name}: ".$sth->errstr());
	return CA::AutoSys::Job->new(database_handle => $self->{dbh}, statement_handle => $sth, parent_job => $self);
}	# find_children()

sub get_status {
	my $self = shift();
	if ($debug) {
		printf("DEBUG: Job(%s): get_status()\n", $self);
	}
	return $self->{status};
}	# get_status()

sub has_children {
	my $self = shift();
	if ($debug) {
		printf("DEBUG: Job(%s): has_children()\n", $self);
	}
	if (!defined($self->{child_cnt}) || $self->{child_cnt} == 0) {
		return 0;
	}
	return 1;
}	# has_children()

1;

__END__

=head1 NAME

CA::AutoSys::Job - Object representing an AutoSys job.

=head1 INSTANCE METHODS

=head2 B<next_job() >

    my $job = $jobs->next_job() ;

Returns the next job from a list of jobs previously acquired by a call to L<find_jobs()|CA::AutoSys/find_jobs()>.

=head2 B<find_children() >

    my $children = $job->find_children() ;

Returns child jobs for a given job object. The child jobs can be traversed like this:

    my $children = $job->find_children() ;
    while (my $child = $children->next_child()) {
        # do something
        :
    }

=head2 B<next_child() >

    my $child = $children->next_child() ;

Returns the next child from a list of child jobs previously acquired by a call to L<find_children() >.

=head2 B<get_status() >

    my $status = $job_or_child->get_status() ;

Returns a hashref that can be queried for job status variables.
See L<CA::AutoSys::Status|CA::AutoSys::Status> for a list of possible status variables.

=head2 B<has_children() >

    my $rc = $job->has_children() ;

Returns 1 if the given job/child has children, 0 otherwise.

=head1 INSTANCE VARIABLES

=head2 B<job_name>

    print "job_name: ".$job->{job_name}."\n";

Contains the name of the AutoSys job.

=head2 B<job_type>

    print "job_type: ".$job->{job_type}."\n";

Contains the type of the job, c=JOB, b=BOX.

=head2 B<joid>

    print "joid: ".$job->{joid}."\n";

Contains the internal job id in the AutoSys database.

=head1 SEE ALSO

L<CA::AutoSys::Status|CA::AutoSys::Status>, L<CA::AutoSys|CA::AutoSys>

=head1 AUTHOR

Sinisa Susnjar <sini@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Sinisa Susnjar. All rights reserved.

This program is free software; you can use and redistribute it under the terms of the L-GPL.
See the LICENSE file for details.
