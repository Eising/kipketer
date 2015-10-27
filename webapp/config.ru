require 'rack'
require 'rack/contrib'
require './app'
require 'pdfkit'
use PDFKit::Middleware, :page_size => 'A4', :print_media_type => true, :footer_center => "[page]/[toPage]", :footer_font_size => 10
use Rack::UTF8Sanitizer

use Rack::MailExceptions do |mail|
    mail.to 'ale@nianet.dk'
    mail.from 'speedtest@hastighedstest.nianetas.local'
    mail.subject '[HASTIGHEDSTEST] %s'
    mail.smtp ({ :address => 'post.nianet.dk' })

end

run Hastighedstest.new

