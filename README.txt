What and Why
============
Microsoft Active Directory servers limit the number of responses
that will be returned for a single query.  If you try to run the
LDAP synchronization script for Moodle, and end up with only, say,
1000 users when you are expecting 2000 users, you may be hitting
this limit.

Ideally, PHP would support LDAP paging.  Then there could be a
generally usable 100% PHP solution to this problem.  Unfortunately,
this will not happen before PHP 5.4, at least.
See https://bugs.php.net/bug.php?id=42060

The way to resolve this problem recommended by Moodlers is to
configure the Active Directory server to have a higher limit.
See http://www.openldap.org/lists/openldap-software/200206/msg00627.html
for one way to do this.

However, sometimes system administrators, in their infinite
wisdom, refuse to raise this limit.  That is the reason that this
workaround exists.


Usage
=====

IMPORTANT: Do not run the synchronization script as the apache user.
When the synchronization script is running, a temporary file is created
that contains, among other things, the username and password of the LDAP
bind user.  This temporary file is chmoded so that only the creating
user can read it.  By default, the temporary file is written in
MOODLEDATA/temp/perlldap/.  This can be changed by setting a value for
$CFG->ldap_perl_temp_dir.

Other than the above, it's just a matter of running the synchronization
script as normal.

The LDAP paging size is currently hardcoded to be 900 in auth/ldap/auth.php,
perhaps this should be made configurable.  Pull requests welcome.


Changed files
=============
auth/ldap/auth.php
  * modified sync_users() so that it calls a helper function
  * added perl_get_users() and perl_temp_dir() to call a perl script
    and load the temporary table created in sync_users() with
    the results

README.txt
  * explain the reason for this branch's existence

Added files:
============
auth/ldap/cli/perl_get_users.pl
  * This is the script which gets executed from PHP in order
    to get the usernames from LDAP using paged results

