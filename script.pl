#!/Users/hob/perl5/perlbrew/perls/perl-5.16.3/bin/perl
# #!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Spreadsheet::Read;
use Data::Dumper;

binmode(STDOUT,':utf8');

chdir '/Users/hob/Downloads/';

my %hash;

my $book = ReadData("seo.xlsx")->[1];
for my $row ($book->{minrow} .. $book->{maxrow}) {
    my $text = $book->{"A$row"};
    $hash{$row} = {
        text    => $text,
        matches => {},
        cnt     => 0,
    };
}

my %h = %hash;

my ($i, %group) = (1, ());
for my $n (keys %h) {
    next unless exists $h{$n};

    push @{$group{$i}{matches}}, $n;
    $group{$i}{cnt}++;
    my $cur = delete $h{$n};

    my @word = split /\s+/, $cur->{text};
# print '--' . join(',', @word) . "\n" if $i == 27;
    for my $nn (keys %h) {
        my @tmp = split /\s+/, $h{$nn}{text};
        my $cnt = 0;
        for my $w (@word) {
            $cnt++ if grep(/^$w$/, @tmp);
        }

        if ($cnt >= 2) {
# print join(',', @tmp) . "\n" if $i == 27;
            push @{$group{$i}{matches}}, $nn;
            $group{$i}{cnt}++;
            delete $h{$nn};
        }
    }

    $i++;
}

$i = 1;
for my $k (sort { $group{$b}{cnt} <=> $group{$a}{cnt}} keys %group) {
    print "Группа $i:\r\n";
    for my $n (@{$group{$k}{matches}}) {
        print "$hash{$n}{text}\r\n";
    }
    print "\r\n";

    $i++;
}
# print Dumper \%group;

# my %group;
# my $i = 1;
# my %tmp = %hash;
# for my $k (sort { $tmp{$b}{cnt} <=> $tmp{$a}{cnt} } keys %tmp) {
#     unless (%{$tmp{$k}{matches}) {
#         delete $tmp{$k};
#         next;
#     }

#     push @{$group{$i}}, $k;
#     my @matches = keys %{$tmp{$k}{matches}};
#     delete $tmp{$k};
#     for my $m (@matches) {
#         push @{$group{$i}}, $m;
#         delete $tmp{$m}{matches}{$k};
#     }

#     print $tmp{$k}{text} . "\n";
#     print "$k - $tmp{$k}{cnt} \n";
#     print Dumper $tmp{$k}{matches};
#     $i++;
# }
# print Dumper \%group;
# print Dumper \%hash;
exit;


sub step1 {
    my $n = shift;

    my %h = %hash;
    my $cur = delete $h{$n};
    my @word = split /\s+/, $cur->{text};

    my $match;
    for my $nn (keys %h) {
        my @tmp = split /\s+/, $h{$nn}{text};
        for my $w (@word) {
            $match->{$nn}++ if grep(/^$w$/, @tmp);
        }
        if ($match->{$nn}) {
            if ($match->{$nn} == 1) {
                delete $match->{$nn};
                next;
            }

            if ($match->{$nn} > $hash{$n}{cnt}) {
                $hash{$n}{cnt}     = $match->{$nn};
                $hash{$n}{matches} = { $nn => 1 };
            }
            elsif ($match->{$nn} == $hash{$n}{cnt}) {
                $hash{$n}{matches}{$nn} = 1;
            }
        }
    }
    return unless %$match;

    # my $best;
    # for $n (sort { $match->{$b} <=> $match->{$a} } keys %$match) {
    #     $best ||= $match->{$n};
    #     delete $match->{$n} if $match->{$n} != $best;
    # }

    # return $match;
}
