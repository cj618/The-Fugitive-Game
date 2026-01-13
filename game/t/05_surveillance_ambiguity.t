use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Surveillance;

my $low = FugitiveGame::State->new_game(name => 'Low', rng_mode => 'seeded', seed => 1);
$low->{player}{meters}{stress} = 5;
$low->{player}{meters}{isolation} = 5;
$low->{player}{meters}{paranoia} = 5;

my $high = FugitiveGame::State->new_game(name => 'High', rng_mode => 'seeded', seed => 1);
$high->{player}{meters}{stress} = 60;
$high->{player}{meters}{isolation} = 60;
$high->{player}{meters}{paranoia} = 60;

my $low_false = 0;
my $high_false = 0;
for (1..20) {
    my $signal_low = FugitiveGame::Surveillance::generate_signal($low, {});
    my $signal_high = FugitiveGame::Surveillance::generate_signal($high, {});
    $low_false++ unless $signal_low->{truth};
    $high_false++ unless $signal_high->{truth};
}

ok($high_false >= $low_false, 'false positives increase under stress');

done_testing;
