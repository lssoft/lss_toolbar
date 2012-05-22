#~ '(C) 2010, Links System Software
#~ 'Feedback information
#~ 'E-mail1: designer@ls-software.ru
#~ 'E-mail2: kirill2007_77@mail.ru (search this e-mail to add skype contact)
#~ 'icq: 328-958-369

#~ lss_toolbar_ext.rb ver. 1.0  17-Apr-12
#~ Set of tools, which provides new geometry creation and advanced manipulation.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

$lsstoolbarStrings = LanguageHandler.new("lsstlbr.strings")

lsstlbr_ext = SketchupExtension.new($lsstoolbarStrings.GetString("LSS Toolbar"), "lss_toolbar/lss_tlbr_loader.rb")

lsstlbr_ext.description=$lsstoolbarStrings.GetString("Set of tools, which provides new geometry creation and advanced manipulation.")
lsstlbr_ext.copyright="(c)2012, Links System Software"
lsstlbr_ext.version="2.0 13-May-12"
lsstlbr_ext.creator="Links System Software"
Sketchup.register_extension(lsstlbr_ext, true)