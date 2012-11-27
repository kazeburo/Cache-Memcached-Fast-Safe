use inc::Module::Install;
name 'Cache-Memcached-Fast-Safe';
all_from 'lib/Cache/Memcached/Fast/Safe.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
#auto_include;
WriteAll;
