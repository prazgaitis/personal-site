---
title: ":christmas_tree: Alexa, turn on the Christmas lights"
layout: post
date: 2017-12-01 20:10
tag: side-project
image: https://media.giphy.com/media/xT0xeN9IRww5jWMQ0M/giphy.gif
headerImage: true
projects: true
hidden: true # don't count this post in blog pagination
description: "A Google Maps for Chicago's Divvy Bike riders"
category: project
author: paulrazgaitis
externalLink: false
---

This year for the holiday season, I decided to try to hook up the Christmas tree to Alexa. I drew inspiration from [Jeff Sacks'](https://twitter.com/jeff_sacks) awesome RubyConf talk, [Voice Controlled Home Automation in Ruby](https://www.youtube.com/watch?v=UaoL8x-brO8), in which he showed how to hook up Alexa to his TV and TiVO.

## Goal

I opted for a much more modest goal than Jeff's - I just wanted to turn my Christmas tree on and off with Alexa. I originally thought about trying to have Alexa enable "christmas mode", which would turn on some music, kill all the lights, light the fireplace, and turn on the tree for a grand finale. I decided on a much more modest goal, and hopefully also avoided burning down the entire building.

## Hardware
1. [IoT Relay](http://amzn.to/2iadgl8) - $30
2. [Electric Imp - April Breakout board](http://amzn.to/2ApXgnw) - $24
3. [Electric Imp card](http://amzn.to/2npoFTs) - $50
4. [a breadboard](http://amzn.to/2nmpPPL) - $7

A little pricey, but luckily I already had all this stuff laying around from older projects.

## Plan

I wanted to use as much IoT hardware that I already had, so the setup needed to be pretty simple. I also wanted the whole thing to be serverless, so Amazon Lambda functions seemed like a great idea.

Turning on the Christmas lights was on and off was pretty simple. I had an [IoT Power Relay](http://amzn.to/2iadgl8) laying around. This device lets you control a power outlet with a Raspberry Pi, Arduino, or other Microprocessor. I used an [Electric Imp](http://amzn.to/2Aqroiz) because I had one that my friend gave me a while back. (Thanks  [Ali](https://twitter.com/h0ngbird)!) The Imp is great because it has a web interface that you can hit with GET requests.

So, the plan looked like this:

1. Plug the lights into the IoT Relay.
2. Use the Electric Imp to turn the power on/off on the relay.
3. Use a Lambda function to control the Electric Imp
4. Make an Alexa skill to run the Lambda function

This is ideal for several reasons. First, the Imp has its own web server, so I don't have to host any code. Second, I don't need to open up ports on my router to the public internet. Jeff solved this problem by using Amazon SQS. Basically, his Lambda function would put a message on a queue, and then his local webserver would poll the Queue for messages every second.


## Let's do it!

Ok let's write the code for the Electric Imp. We need Agent code (the web server), and the Device code (the code that the Imp runs)

```js
function requestHandler(request, response) {
    try {
        // Check if the user sent power as a query parameter
        if ("power" in request.query) {
            // If we got the power
            if (request.query.power == "1" || request.query.power == "0") {
                // Convert the power query parameter to an integer
                local powerState = request.query.power.tointeger();

                // Send "setPower" message to device, and send powerState as the data
                device.send("setPower", powerState);
            }
        }
        // Send a response back to the browser saying everything was OK.
        response.send(200, "OK cool");
    } catch (ex) {
        response.send(500, "Internal Server Error: " + ex);
    }
}

// Register the HTTP handler to begin watching for HTTP requests from your browser
http.onrequest(requestHandler);
```

And the device code:

```js
// Device code (the Elctric imp runs this)
// 1. create a variable for the output pin
relay <- hardware.pin9;

// 2. Set the pin to 0
relay.configure(DIGITAL_OUT, 0);

function setPowerState(state) {
    server.log("Turning power on/off: " + state);
    relay.write(state);
}

// Register a handler for incoming messages from the Imp agent
agent.on("setPower", setPowerState);
```

Now that we have the code for the Electric Imp, lets test it out. We can hit the Electric Imp server with curl:

```bash
curl -i "https://agent.electricimp.com/**************?power=1"
```

The response should look like this.
```bash
HTTP/1.1 200 OK
Date: Tue, 05 Dec 2017 19:03:35 GMT
Server: nginx/1.4.6 (Ubuntu)
Content-Length: 7
Connection: keep-alive

OK cool
```

TODO: IMP setup

Great! It works just how we expected. Next, let's create a Lambda function to do the same thing.

## Creating an AWS Lambda Function

```markdown
(do alexa stuff first, since we need the intent names for the lamdba code)

Steps:
1. Log into https://console.aws.amazon.com/
2. Go to https://console.aws.amazon.com/lambda/home
3. Click on `Create function`
4. Fill out the form: https://www.dropbox.com/s/hn8iqi7mty00dt2/Screenshot%202017-12-05%2013.12.04.png?dl=0
5. Write function
```

the starter code looks like this:
```js
exports.handler = (event, context, callback) => {
    // TODO implement
    callback(null, 'Hello from Lambda');
};
```

We basically just need it to make a single web request, so it won't need to be much more complicated than that.

```js
var http = require('http');
let baseUrl = "http://agent.electricimp.com/XiXAucUdTaAa?power=";

function turnItOn () {
    let url = baseUrl + "1";
    sendRequest(url);
}

function turnItOff () {
    let url = baseUrl + "0";
    sendRequest(url);
}

function sendRequest (url) {
    http.get(url, (res) => {
        console.log("Got response: " + res.statusCode);
    }).on('error', (e) => {
        console.log("Got an error: " + e.message);
    })
}

exports.handler = (event, context, callback) => {
    try {
        let intentName = event['request']['intent']['name']
        intentName == "TreeOnIntent" ? turnItOn() : turnItOff();
    } catch (e) {
        turnItOn() // lets turn on the tree, just in case
    }

    let response = {
      "version": "1.0",
      "response": {
        "outputSpeech": {
          "type": "PlainText",
          "text": "ok",
          "ssml": "<speak>ok</speak>"
        }
      }
    }
    callback(null, response);
};
```

```markdown
Alexa stuff:
1. Go here: https://developer.amazon.com/alexa
2. Click 'Get started' under Alexa Skills kit
3. Click 'Add a new skill'
4. Choose an invocation name: https://www.dropbox.com/s/y4m73ag75urz5ar/Screenshot%202017-12-05%2016.54.20.png?dl=0
https://www.dropbox.com/s/50t4ann5iwgioga/Screenshot%202017-12-05%2017.03.38.png?dl=0
5. Read amazon doc about how users invoke skills: https://developer.amazon.com/docs/custom-skills/understanding-how-users-invoke-custom-skills.html
```

This part was tricky at first. I wanted to be able to say `Alexa, turn on the tree`, but the phrase `turn on...` tells Alexa to look for a Smart Home Skill API. That's a little more complicated to set up, because you have to register your Smart Device and authenticate it. Lets avoid that for now. 

Since we need to stick to custom skill invocations, we need to pick something along these lines:

"Alexa, *ask* christmas tree to light up"
"Alexa, *ask* christmas tree off/on"
"Alexa, *tell* christmas tree to light up"
"Alexa, *load* christmas tree and turn it on"
"Alexa, *run* christmas tree and turn on the lights
"Alexa, *start* christmas tree on"

[Here's a good doc from Amazon explaining all this stuff.](https://developer.amazon.com/docs/custom-skills/understanding-how-users-invoke-custom-skills.html)

Some of these are a little clunky, but they'll do the trick. (Let me know if you have better ways of solving this!)

Next up, we define the interaction model. Amazon has a new Skill Builder in Beta that I really liked using.

![skill builder](https://www.dropbox.com/s/2vph6rgq4bk8nnw/Screenshot%202017-12-05%2017.04.27.png?dl=0)

Lets start by making a new Intent.
![new intent](https://www.dropbox.com/s/jup1s5ojxmpokpn/Screenshot%202017-12-05%2017.05.31.png?dl=0)

We will need two Intents - one to turn the tree on, and another to turn it off.

![](https://www.dropbox.com/s/jblzueyii38yb7y/Screenshot%202017-12-05%2017.08.03.png?dl=0)

I named them `TreeOnIntent` and `TreeOffIntent`. After we name the intent, we need to add `utterances`. These are the things that come after the invocation name when someone is speaking to Alexa. The whole command breaks down like this: "Alexa, [ask|tell|load|run|start] [invocation name] [utterance]". For the TreeOnIntent, I used these utterances:

```bash
on
tree on
light the tree
lights on
christmas tree on
light it up
```

Make sure you add a `TreeOffIntent`, and write the opposite of the utterances for turning it on. Next, click *Save Model* and then *Build Model* in the top menu. This step can take a few minutes. Once it's done, click on *Configuration* in the top menu bar. Now we're back out in the configuration wizard. This is where we hook up the Lamdba function. Go back to the page where you created your Lambda function and find the ARN in the top right corner.

It will look like this: `arn:aws:lambda:us-east-1:12345678987:function:christmasTree`

Before we hit Next, we need to set up the event source type for our Lambda function. Go back to the same Lambda page where you found the ARN and click on Alexa Skills Kit from the list of Triggers.

![list of triggers](https://www.dropbox.com/s/jqdxldigkivhycq/Screenshot%202017-12-05%2017.28.58.png?dl=0)

Once you click ont the Alexa Skills Kit, go down to the *Configure Triggers* section and click *add*. Save your function and then head back to the Configuration tab of the Alexa Skill wizard. You shoudl now be able to hit Save and Next.

### Testing your Alexa Skill

This is where we test the utterances. Try typing any of the utternaces in the Service Simulator.

If it looks like this and your tree turned on, it works!!

![it works](https://media.giphy.com/media/xUOxfkPDn7JCdQWxb2/giphy.gif)

Your skill should automatically be enabled in your Alexa account, but you can go check it out by logging into your account at [here](https://alexa.amazon.com/spa/index.html).

And that's all there is to it! Let me know if you end up making one of these!

<div style="width:100%;height:0;padding-bottom:50%;position:relative;"><iframe src="https://giphy.com/embed/xUOxeTRZskgbRdezNm" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div>

