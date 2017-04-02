
Ruby on Rails
-------------

This application requires:

- Ruby 2.2.1
- Rails 4.2.5.1

Learn more about [Installing Rails](http://railsapps.github.io/installing-rails.html).

Getting Started
---------------

Documentation and Support
-------------------------

Issues
-------------

Similar Projects
----------------

Contributing
------------

Credits
-------

License
-------

Run BitgoJS
------------------------------------------------------------------

Install Bitgo on server  : clone Bitgojs (Not in Project Directory)
1: git clone https://github.com/BitGo/BitGoJS.git

2: cd BitgoJs

3: npm install

4: cd BitgoJs/bin

5: Run  ./bitgo-express --debug --port 3080 --env prod --bind localhost

if you see following error:

(http://stackoverflow.com/questions/30281057/node-forever-usr-bin-env-node-no-such-file-or-directory)

Then

sudo ln -s "$(which nodejs)" /usr/bin/node

And Again:

 ./bitgo-express --debug --port 3080 --env prod --bind localhost



 after installing BITGOJS  get access token
 ------------------------------------------------

 go to
 https://www.bitgo.com/
 Create account and Login


 You can request long-lived access tokens which do not expire after 1 hour and are unlocked for a certain amount in funds.

 Access the BitGo dashboard and head into the “Settings” page.
 Click on the “Developer” tab.
 You can now create a long-lived access token.
 The token will come unlocked by default with your specified spending limit. Do not attempt to unlock the token again via API as this will reset the unlock.

 TOKEN PARAMETERS


 Label	:A label used to identify the token so that you can choose to revoke it later.
 Duration:	Time in seconds which the token will be valid for.
 Spending Limit:	The token will come unlocked for a spending limit up this amount in BTC. Do not attempt to unlock the token via API as this will reset the limit.
 IP Addresses:	Lock down the token such that BitGo will only accept it from certain IP addresses.
 Permissions:	Auth Scope that the token will be created wit



Fill Token Label with ACCESS_TOKEN and other field as you want  , ip address of server (machine on which we want to run access token)
click on add token then verify (by mobile or email ) after verifying save the token on secure place
 and  paste your bitgo access token in  /config/application.yml
   access_token: "paste here"
