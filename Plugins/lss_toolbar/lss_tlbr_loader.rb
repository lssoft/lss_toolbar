#~ '(C) 2010, Links System Software
#~ 'Feedback information
#~ 'E-mail1: designer@ls-software.ru
#~ 'E-mail2: kirill2007_77@mail.ru (search this e-mail to add skype contact)
#~ 'icq: 328-958-369

#~ chronolux.rb ver. 1.0  17-Apr-12
#~ The script, which loads all available LSS Toolbar tools

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

#initializes $lssToolbar and $lssMenu
require 'lss_toolbar/lss_toolbar.rb'

#initializes '2 Faces Plus Path...' tool
require 'lss_toolbar/lss_pathface.rb'

#initializes scripts, which are common for all tools (refresh, tools observer etc)
require 'lss_toolbar/lss_tlbr_common.rb'

#loads the script, which contains some utility stuff such as progress bar etc
require 'lss_toolbar/lss_tlbr_utils.rb'