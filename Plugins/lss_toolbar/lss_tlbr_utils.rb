# lss_tlbr_utils.rb ver. 1.0.  17-Apr-12
# Utility ccript, which contains LSS Toolbar utility classes.

#~ '(C) 2010, Links System Software
#~ 'Feedback information
#~ 'E-mail1: designer@ls-software.ru
#~ 'E-mail2: kirill2007_77@mail.ru (search this e-mail to add skype contact)
#~ 'icq: 328-958-369

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

# This is a class, which contains small progress bar string generation

class Lss_Toolbar_Progr_Bar
  attr_accessor :percents_ready
  attr_accessor :progr_string
  
  # Read input parameters
  def initialize(tot_cnt,progr_char,rest_char,scale_coeff)
    @scale_coeff=scale_coeff
    @scale_coeff=2 if @scale_coeff==nil or @scale_coeff==0
    if tot_cnt
      @tot_cnt=tot_cnt
      @tot_cnt=1 if @tot_cnt==0
    end
    @progr_char=progr_char
    @rest_char=rest_char
    @percents_ready=0
  end
  
  # Generate progress bar string using given input parameters
  def update(curr_cnt)
    @curr_cnt=curr_cnt
    @percents_ready=(100*@curr_cnt/(@tot_cnt)).round
    if 100/@scale_coeff-(@percents_ready/@scale_coeff)>= 0
      progr_str=@progr_char*((@percents_ready/@scale_coeff).round)+@rest_char*(100/@scale_coeff-(@percents_ready/@scale_coeff).round)
    else
      progr_str=@progr_char*((100/@scale_coeff).round)
    end
    @progr_string="#{@percents_ready}% #{progr_str}"
  end
end #class Lss_Toolbar_Progr_Bar