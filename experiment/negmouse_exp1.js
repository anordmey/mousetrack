// --------------- HELPER FUNCTIONS ----------------
function random(a,b) {
    if (typeof b == "undefined") {
	a = a || 2
	return Math.floor(Math.random()*a)
    } else {
	return Math.floor(Math.random()*(b-a+1)) + a
    }
}

Array.prototype.random = function() {
  return this[random(this.length)];
}

function shuffle(array) {
    var tmp, current, top = array.length
    if(top) while(--top) {
        current = Math.floor(Math.random() * (top + 1))
        tmp = array[current]
        array[current] = array[top]
        array[top] = tmp
    }    
    return array
}

function showSlide(id) {
    $(".slide").hide()
    $("#"+id).show()
}

function makeLinkIm (size, imname) {
    return '<img height=' + size + ' src=\"images/' + imname + '.jpg\"><p align=\"center\"></p>'
}

function makeQuestionText (q_text) {
    return '<p align=\"center\">' + q_text + '</p>'
}

//preload images: 
var myimages = new Array();
function preloading(){
    for (x=0; x<preloading.arguments.length; x++){
	myimages[x] = new Image();
	myimages[x].src = preloading.arguments[x];
    }
}
preloading()

function getRadioCheckedValue(formNum, radio_name)
{
    var oRadio = document.forms[formNum].elements[radio_name]
    for(var i = 0; i < oRadio.length; i++)
    {
	if(oRadio[i].checked)
	{
            return oRadio[i].value
	}
    }
    return ''
}

function clearForm(oForm) {
    var elements = oForm.elements
    oForm.reset()
    for(i=0; i<elements.length; i++) {
	field_type = elements[i].type.toLowerCase()
	switch(field_type) {
	case "text": 
	case "password": 
	case "textarea":
	case "hidden":	
	    elements[i].value = ""
	    break
	case "radio":
	case "checkbox":
  	    if (elements[i].checked) {
   		elements[i].checked = false
	    }
	    break
	case "select-one":
	case "select-multi":
            elements[i].selectedIndex = -1
	    break
	default: 
	    break
	}
    }
}

function ValidateForm(form){
    var valid = 0
    for(var i = 0; i < form.elements.length; i++) {
        if (form.elements[i].checked == true ) { 
            valid = 1
            return true
        } 
    } 
    if (valid == 0) {
        alert ( "Please answer this question." )
        return false
    }
}

function ValidateSelect(form) {
    if (form.ageRange.selectedIndex != 0 && form.ageRange.selectedIndex != 1 && form.ageRange.selectedIndex != 2 && form.ageRange.selectedIndex != 3 && form.ageRange.selectedIndex != 4 && form.ageRange.selectedIndex != 5 && form.ageRange.selectedIndex != 6) {
        alert ( "Please answer this question." )
        return false
    }
    return true
}
function ValidateText(field)
{
    valid = true
    if (field.value == "" )
    {
        alert ( "Please answer all the questions." )
        valid = false
    }
    return valid
}
// --------------- PARAMETERS OF THE EXPERIMENT ----------------
//list of item names, for easy identification
var items = ["pillow","circles","pants","people","phones","sky","bear","grass","ground","secrets","fire","rocket"]

//list of sentences for each item.  4 sentences per item.  first is true pos, second is false pos, third is true neg, fourth is false neg.
var sentences = [
    [["a","pillow","is","soft"],
     ["a","pillow","is","hard"],
     ["a","pillow","is","not","hard"],
     ["a","pillow","is","not","soft"]],
    [["circles","are","shapes"],
     ["circles","are","squares"],
     ["circles","are","not","squares"],
     ["circles","are","not","shapes"]], 
    [["pants","have","legs"],
     ["pants","have","arms"],
     ["pants","have","no","arms"],
     ["pants","have","no","legs"]],
    [["people","ride","bikes"],
     ["people","fly","bikes"],
     ["people","never","fly","bikes"],
     ["people","never","ride","bikes"]],
    [["phones","are","dialed"],
     ["phones","are","eaten"],
     ["phones","are","not","eaten"],
     ["phones","are","not","dialed"]],
    [["the","sky","is","blue"],
     ["the","sky","is","green"],
     ["the","sky","is","not","green"],
     ["the","sky","is","not","blue"]],
    [["a","bear","is","large"],
     ["a","bear","is","small"],
     ["a","bear","is","not","small"],
     ["a","bear","is","not","large"]],
    [["grass","is","green"],
     ["grass","is","blue"],
     ["grass","is","not","blue"],
     ["grass","is","not","green"]],
    [["the","ground","is","below"],
     ["the","ground","is","above"],
     ["the","ground","is","not","above"],
     ["the","ground","is","not","below"]],
    [["secrets","are","private"],
     ["secrets","are","public"],
     ["secrets","are","not","public"],
     ["secrets","are","not","private"]],
    [["a","fire","is","hot"],
     ["a","fire","is","cold"],
     ["a","fire","is","not","cold"],
     ["a","fire","is","not","hot"]],
    [["a","rocket","is","fast"],
     ["a","rocket","is","slow"],
     ["a","rocket","is","not","slow"],
     ["a","rocket","is","not","fast"]]
]

//trial types.  0 is true pos, 1 is false pos, 2 is true neg, 3 is false neg
var trialTypes = shuffle([0,0,0,1,1,1,2,2,2,3,3,3])

var allButtonOrders = [
    {"left":"TRUE","right":"FALSE"},
    {"left":"FALSE","right":"TRUE"},
]

//randomly determine which side True and False are on the screen (between-subjects)
var myButtonOrders = allButtonOrders.random()

//trial order is randomized for each subject
var trialOrder = shuffle([0,1,2,3,4,5,6,7,8,9,10,11])

// --------------- EXPERIMENT ----------------------------------------
showSlide("instructions")
$("#instructionsText").html("Thank you for your work on this brief HIT. <p></p> In the next pages, you will see \"TRUE\" and \"FALSE\" boxes at the top of the screen. At the bottom, you will see a black circle. By clicking the circle with your mouse, you will reveal a simple sentence in a word-by-word fashion. When the sentence is complete, the circle will disappear. <p></p> At this point, respond accordingly by clicking on a \"FALSE\" or \"TRUE\" box with your computer mouse. For example, if the sentence is \"houses are buildings\" the response would be \"TRUE\". If the sentence is \"houses are not buildings\" the response would be \"FALSE\". <p></p> Click start to begin.")

if (turk.previewMode == true) {
$("#startButton").attr("disabled", "disabled")
}

var experiment = {
    trials: trialOrder,
    completed: [],
    leftSide: myButtonOrders["left"], 
    data: [],
    gender: [],
    age:"",
    nativeLanguage:"",
    mouse:"",
    comments:"",
    
    //start trials
    nextTrial: function() {
	var n = experiment.trials.shift() 
	if (typeof n == "undefined") {
	    return experiment.background()
	}
	
	//this maintains a list of the order of trials
	experiment.completed.push(n)

	//start with word button visible, no sentence words, and true/false buttons disabled
	$("#wordButton").show()
	$("#sentenceWord").html("")
	$(".choiceButton").attr("disabled", "disabled")

	showSlide("stage")

	$("#leftResponse").html(myButtonOrders["left"])
	$("#rightResponse").html(myButtonOrders["right"])

	//length of the sentence given in this trial
	var sentenceLength =  []
	for (i=0; i<sentences[n][trialTypes[n]].length; i++) {
	    sentenceLength.push(i)   
	}
			      
	//keep track of sentence type and truth value for each trial:
	// 0 is true pos, 1 is false pos, 2 is true neg, 3 is false neg
	//var sentenceType = sentenceType
	//var truthVal = truthVal
	if (trialTypes[n] == 0) {
	    var sentenceType = "pos"
	    var truthVal = "TRUE"
	} else if (trialTypes[n] == 1) {
	    var sentenceType = "pos"
	    var truthVal = "FALSE"
	} else if (trialTypes[n] == 2) {
	    var sentenceType = "neg"
	    var truthVal = "TRUE"
	} else if (trialTypes[n] == 3) {
	    var sentenceType = "neg"
	    var truthVal = "FALSE"
	}   

	var firstClick = true
	var startReadTime = null
	//for reading times:
	var readTime = []
	
	//when black button is clicked"
	$("#wordButton").off('click').on('click', (function() {

	    //first time the button is clicked:
	    if (firstClick == true) {
	     	startReadTime = (new Date()).getTime()
	     	firstClick = false
	    }
	    
	    //this function changes the word presented each time the black button is clicked.

	    function changeWord (index) {
		var m = index.shift()
		$("#sentenceWord").html(sentences[n][trialTypes[n]][m])
		$("#wordButton").show()
		if (index.length == 0) {
		    $("#wordButton").hide()
		}
	    }

	    changeWord(sentenceLength)

	    readTime.push((new Date()).getTime() - startReadTime)

	    //when black button is clicked for the last time:
	    if (sentenceLength.length == 0) {
	 	var startTime = (new Date()).getTime()

		//enable true/false buttons
		$(".choiceButton").removeAttr("disabled")
		
		//track mouse coordinates: 
		
		//constantly keep track of mouse coordinates
		$(document).mousemove(function(e) {
		    window.mouseX = e.pageX
		    window.mouseY = e.pageY
		})

		var xCoord = []
		var yCoord = []
		var cTime = []
		
		//only record mouse coordinates every 25 ms
		timer = setInterval(function() {
		    if (window.mouseX) {
			xCoord.push(window.mouseX)
			yCoord.push(window.mouseY)
			cTime.push((new Date()).getTime() - startTime)
		    }
		}, 25)
		
	    }
	    
	    var totalReadTime = readTime[readTime.length-1]

	   //when TRUE or FALSE is selected:  
	    $(".choiceButton").off('click').on('click', (function() {
		$(".choiceButton").off("click")

		var endTime = (new Date()).getTime()

		//stop tracking mouse coordinates
		$(document).unbind('mousemove')
		// stop recording mouse coordinates
		clearInterval(timer)
		//reset mouse coordinates (otherwise the first few coordinates recorded are actually the coordinates of the decision from the previous trial - since it takes about 100 ms to initiate a mouse movement)
		window.mouseX = null
		window.mouseY = null

		// figure out if they chose true or false
		selection = $(this).text().replace(/\s+/g, '')
		
		//check accuracy
		if (truthVal == selection) {
		    var correct = 1
		} else {
		    var correct = 0
		}
		
		//reformat readTime so that each number refers to the reading time for the comparable word in the readWord array.  
		readTime.shift()
		readTime.push(totalReadTime + (endTime - startTime))

		//this is the data that is collected for each trial: 
		var data = {
		    leftSide: myButtonOrders["left"],
		    item: items[n],
		    sentence: sentences[n][trialTypes[n]],
		    truth: truthVal,
		    type: sentenceType,
		    selection: selection,
		    correct: correct, 
		    xCoord: xCoord,
		    yCoord: yCoord,
		    coordTiming: cTime,
		    rt: endTime - startTime,
		    readTime: readTime,
		    totalReadTime: totalReadTime,
		     //note that "totalReadTime is actually the total reading time for all but the final word of the sentence.  To get total time from start of reading sentence to decision, do totalReadTime + rt.  Getting actual reading time is not possible because we don't know how long they spend reading the final word (aka the final number in the readTime array)
		    condition: "no context"
		}
		
		experiment.data.push(data)
		//setTimeout(experiment.nextTrial, 500)
		
	    }))
	}))
    },
    
    //Ask for background info and comments:
    background: function() {
	window.onkeydown = function(e) {
	}
        clearForm(document.gender);
        clearForm(document.age);
        clearForm(document.comments);
        showSlide("askInfo");
    },
    
    // finish 
    end: function() {
	var gen = getRadioCheckedValue(0, "genderButton")
        var ag = document.age.ageRange.value
        var lan = document.language.nativeLanguage.value
	var mouse = getRadioCheckedValue(3, "mouseButton")
        var comm = document.comments.input.value
	experiment.gender = gen
        experiment.age = ag
        experiment.nativeLanguage = lan
	experiment.mouse = mouse
	experiment.comments = comm
	showSlide("finished")
	
	setTimeout(function() { turk.submit(experiment) }, 1500)
    }
}
