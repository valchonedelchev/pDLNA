package PDLNA::Statistics;
#
# pDLNA - a perl DLNA media server
# Copyright (C) 2010-2013 Stefan Heumader <stefan@heumader.at>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;

use Proc::ProcessTable;

use PDLNA::Config;
use PDLNA::Daemon;
use PDLNA::Database;
use PDLNA::Log;

sub write_statistics_periodic
{
	PDLNA::Log::log('Starting thread for writing statistics periodically.', 1, 'default');
	while(1)
	{
		my $dbh = PDLNA::Database::connect();

        my $proc = Proc::ProcessTable->new();
		my %fields = map { $_ => 1 } $proc->fields;
		return undef unless exists $fields{'pid'};
		my $pid = PDLNA::Daemon::read_pidfile($CONFIG{'PIDFILE'});
		foreach my $process (@{$proc->table()})
		{
			if ($process->pid() eq $pid)
			{
				PDLNA::Database::insert_db(
					$dbh,
					{
						'query' => 'INSERT INTO STAT_MEM (DATE, VMS, RSS) VALUES (?,?,?)',
						'parameters' => [ time(), $process->{size}, $process->{rss}, ],
					},
				);
			}
		}

		PDLNA::Database::disconnect($dbh);

		sleep 60;
	}
}

1;