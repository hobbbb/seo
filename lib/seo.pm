package seo;
use Dancer ':syntax';
use Data::Dumper;
use Spreadsheet::Read;
use Encode qw/decode/;

our $VERSION = '0.1';

get '/seo' => sub {
    template 'index';
};

post '/seo' => sub {
    my $file = request->upload('file');

    my $res;
    my %hash;
    my $book = ReadData($file->{tempname})->[1];

    for my $row ($book->{minrow} .. $book->{maxrow}) {
        my $text = decode('utf8', $book->{"A$row"});
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
        my @arr;
        for my $n (@{$group{$k}{matches}}) {
            push @arr, $hash{$n}{text};
        }
        push @$res, {
            name => "Группа $i",
            word => \@arr,
        };
        $i++;
    }

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

    return template 'index' => {
        group => $res,
    };
};

true;
