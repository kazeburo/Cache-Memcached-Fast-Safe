use inc::Module::Install;
name 'Cache-Memcached-Fast-Safe';
all_from 'lib/Cache/Memcached/Fast/Safe.pm';

requires 'Cache::Memcached::Fast' => '0.19';
requires 'URI::Escape::XS'        => '0.09';
requires 'parent'                 => '0';
requires 'POSIX::AtFork'          => '0.02';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::TCP';
test_requires 'Test::Skip::UnlessExistsExecutable';
test_requires 'File::Which';
test_requires 'Proc::Guard';

auto_set_repository;
WriteAll;
