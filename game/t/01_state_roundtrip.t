use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Save;

my $dir = tempdir(CLEANUP => 1);
my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 42);
$state->{player}{meters}{stress} = 33;
my $path = FugitiveGame::Save::save_state($state, $dir);
my $loaded = FugitiveGame::Save::load_state($path);

is($loaded->{player}{name}, 'Tester', 'name roundtrip');
is($loaded->{player}{meters}{stress}, 33, 'meter roundtrip');
is($loaded->{player}{rng}{seed}, 42, 'seed roundtrip');

ok(-e $path, 'save file exists');

done_testing;
