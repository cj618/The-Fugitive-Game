use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FugitiveGame::State;
use FugitiveGame::Agency;

my $state = FugitiveGame::State->new_game(name => 'Tester', rng_mode => 'seeded', seed => 5);
for my $agency (values %{$state->{agencies}}) {
    $agency->{coordination} = 10;
}

my $saw_event = 0;
for (1..20) {
    my $result = FugitiveGame::Agency::apply_slot($state);
    $saw_event = 1 if $result->{stall} || $result->{spike};
}

ok($saw_event, 'low coordination yields friction events');

done_testing;
