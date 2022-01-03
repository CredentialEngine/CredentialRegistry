# The validator base class was renamed at some point,
# but grape-kaminari hasn't been upgraded to use the new name yet
Grape::Validations::Base = Grape::Validations::Validators::Base

require 'grape-kaminari'
