require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  test "line parsing" do
    sample_text = %Q{EI03       C      LUNDI... 18:45-19:45,F1,S=RN104/EI03       C      LUNDI... 18:45-19:45,F1,S=RN104
 EI03       D 1    SAMEDI..  8:15-12:15,F1,S=RN104

 LG30       D 2    MERCREDI 10:15-12:15,F1,S=FA413
 LG30       T 3    LUNDI... 13:00-14:00,F1,S=FA410

 SR01       C      LUNDI... 14:15-16:15,F1,S=FA104
 SR01       D 1    LUNDI... 16:30-18:30,F1,S=FA506


 MT12       C      LUNDI...  8:00-10:00,F1,S=FA202
 MT12       D 1    MARDI... 16:30-18:30,F1,S=FA518

SPJE       D 1    JEUDI... 14:15-18:15,F1,S=     *}
    lines = sample_text.split('\n')

  end
end
