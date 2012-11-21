
# A librarian git repo containing chef cook books for WISE4 servers #

This repository only contains chef cookbooks. It can be used by other projects using [librarian][librarian]. It should be consumed by another project such as [wise-chef][wise-chef] – a simple replacement for the older [wise4-vagrant][wise4-vagrant]. 

*NOTE*: most of these cookbooks are *not* used, exceptions are 'vagrant_main' and 'wise4'. The other cookbooks can and should be deleted.

### Todo: ###

1. remove all cookbooks other than wise4 and vargrant_main
2. rename vagrant_main or roll it into the wise4 recipe.
3. improve this documentation
4. update wise4-vagrant to use librarian.
5. Browse the opscode knife & Chef [plugins-page][plugins-page]. Note that there are already plugins for [knife-ec2][knife-ec2], [kife-solo][knife-solo], and [knife-hatch][knife-hatch]


### Refs: ###

* [wise-cookbooks][wise-cookbooks] This project. A simple set of chef cookbooks. (Only vagrant main and wise4 are used.)
* [wise-chef][wise-chef] Consumes this librian repo. Can be used to setup a wise4 development environment on ec2 servers. 
*  [wise4-vagrant][wise4-vagrant] The old system for deploying to vagrant. The wise4-ec2 branch
* [Librarian][librarian] use git to distribute chef cookbooks. 
* [Wise Developers git repository][WISE Github]

[wise-cookbooks]: https://github.com/concord-consortium/wise-cookbooks
[wise4-vagrant]: https://github.com/concord-consortium/wise4-vagrant/tree/wise4-ec2
[wise-chef]: https://github.com/concord-consortium/wise-chef
[wise-cloud]: https://github.com/concord-consortium/wise-cloud

[librarian]: https://github.com/applicationsonline/librarian

[plugins-page]: http://wiki.opscodecom/display/chef/Community+Plugins
[knife-ec2]: https://github.com/opscode/knife-ec2
[knife-solo]: https://github.com/matschaffer/knife-solo
[knife-hatch]: https://github.com/xdissent/chef-hatch-repo

[WISE Github]: https://github.com/WISE-Community
[WISE]: http://wise.berkeley.edu/
