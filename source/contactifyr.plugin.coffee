nodemailer = require 'nodemailer'
axios = require 'axios'
# docpad = require 'docpad'

module.exports = (BasePlugin) ->

	class ContactifyPlugin extends BasePlugin
		name: 'contactifyr'

		config:
			contact:
				path: '/contact-form'
			# No from necessary if using an existing account (which will have its own 'from')
				# from: 'me@site.name',
				redirect: '/'
				to: 'me@site.name'
				subject: 'Inquiry' # OPTIONAL
				transport: {
					service: 'Gmail',
					host: 'smtp.ethereal.email',
					port: 587,
					secure: false,
					auth: {
						user: 'contact@me.com',
						pass: 'password'
					}
				}

		serverExtend: (opts) ->
			{server} = opts

			config = @getConfig()
			smtp = nodemailer.createTransport(config.transport)

			server.post config.contact.path, (req, res) ->
				receivers = []
				enquiry = req.body
				console.log('enquiry:', enquiry)
				# data = {
				# 	secret: '',
				# 	response: enquiry['g-recaptcha-response']
				# }
				parameters = '?secret=foobar&response=' + enquiry['g-recaptcha-response']
				url = 'https://www.google.com/recaptcha/api/siteverify' + parameters
				console.log('url is', url)
				axios.post(url).then (response) ->
					console.log(response)
					# if recaptcha response fails do not send
					if response.success
						# if 'honeypot' field filled out, do not send
						if not enquiry.email || enquiry.email == ''
							receivers.push(enquiry.redbox_email, config.contact.to)
							mailOptions = {
								to: receivers.join(","),
								subject: 'Enquiry from ' + enquiry.fname + ' ' + enquiry.lname + ' <' + enquiry.redbox_email + '>',
								text: enquiry.message,
								html: '<p>' + enquiry.message + '</p>'
							}
							smtp.sendMail mailOptions, (err, resp) ->
								if(err)
									console.log("There was an error sending email", err)
								else
									console.log("send mail response:", resp)

				res.redirect config.contact.redirect

			@
