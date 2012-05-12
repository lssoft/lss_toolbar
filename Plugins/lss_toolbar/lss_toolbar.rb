# lss_toolbar.rb ver. 1.0  17-Apr-12
# The script, which initializes LSS Toolbar and LSS Tools submenu

#~ '(C) 2010, Links System Software
#~ 'Feedback information
#~ 'E-mail1: designer@ls-software.ru
#~ 'E-mail2: kirill2007_77@mail.ru (search this e-mail to add skype contact)
#~ 'icq: 328-958-369

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

# Thic class initializes LSS Toolbar and LSS Tools submenu

class Lss_Tools_Toolbar
    def initialize
      $lssToolbar = UI::Toolbar.new($lsstoolbarStrings.GetString("LSS Toolbar"))
      $lssMenu = UI.menu("Plugins").add_submenu($lsstoolbarStrings.GetString("LSS Tools"))
    end
  end #class Lss_Tools_Toolbar
  
if( not file_loaded?("lss_toolbar.rb") )
  lss_toolbar=Lss_Tools_Toolbar.new
end

#-----------------------------------------------------------------------------
file_loaded("lss_toolbar.rb")