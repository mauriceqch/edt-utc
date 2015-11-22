$(document).ready(function() {
    $('#selected_color').minicolors({theme: 'bootstrap'})

    // page is now ready, initialize the calendar...

    colors = {};
    for(var i = 0; i < courses.length; i++) {
        colors[courses[i]] = randomColor({luminosity: 'dark'});
    }

    function eventCourse(event) {
        return event.title.substr(0,4);
    }

    for(var i = 0; i < courses_events.length; i++) {
        courses_events[i].backgroundColor = colors[eventCourse(courses_events[i])];
    }

    $('#calendar').fullCalendar({
        defaultView: 'agendaWeek',
        minTime: '8:00:00',
        maxTime: '20:00:00',
        allDaySlot: false,
        contentHeight: 'auto',
        hiddenDays: [0],
        firstDay: 1,
        columnFormat: 'dddd',
        events: courses_events,
        eventClick: function(event, element) {

            color = $('#selected_color').val();

            $('#calendar').fullCalendar('updateEvent', event);
            var events = $('#calendar').fullCalendar('clientEvents', function(evt) {
                return eventCourse(evt) == eventCourse(event);
            });
            for (var i = 0; i < events.length; i++) {
                if (color != "") {
                    events[i].backgroundColor = color;
                    $('#calendar').fullCalendar('updateEvent', events[i]);
                }
            }

        }
    })

    $('.fc-toolbar').remove();
    $("#pngbutton").click(function () {
html2canvas($("#calendar"), {
     onrendered: function (canvas) {
         // canvas is the final rendered <canvas> element
         var myImage = canvas.toDataURL("image/png");
         window.open(myImage);
     }})
 });
    $("#pdfbutton").click(function () {
        html2canvas($('#calendar-container'), {
            logging: true,
            useCORS: true,
            background: "#ffffff",
            onrendered: function (canvas) {
                var imgData = canvas.toDataURL("image/jpeg");
		var imgTemp = new Image;
		imgTemp.src = imgData;
        // Keep image ratio while inserting into PDF
		var ratio = imgTemp.width / imgTemp.height;
		
                var doc = new jsPDF("landscape");
		if (ratio > 1.414) {
                	doc.addImage(imgData, 'jpeg', 10, 210-(277/ratio), 277, 277/ratio);
		} else {
                	doc.addImage(imgData, 'jpeg', (297-(190*ratio))/2, 10, 190*ratio, 190);
		}

                download(doc.output(), "edt.pdf", "text/pdf");
            }
        });
    }); // $("#calendar_btn_pdf").click(function ()

    function download(strData, strFileName, strMimeType) {
        var D = document,
            A = arguments,
            a = D.createElement("a"),
            d = A[0],
            n = A[1],
            t = A[2] || "text/plain";

        //build download link:
        a.href = "data:" + strMimeType + "," + escape(strData);

        if (window.MSBlobBuilder) {
            var bb = new MSBlobBuilder();
            bb.append(strData);
            return navigator.msSaveBlob(bb, strFileName);
        } /* end if(window.MSBlobBuilder) */

        if ('download' in a) {
            a.setAttribute("download", n);
            a.innerHTML = "downloading...";
            D.body.appendChild(a);
            setTimeout(function() {
                var e = D.createEvent("MouseEvents");
                e.initMouseEvent("click", true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
                a.dispatchEvent(e);
                D.body.removeChild(a);
            }, 66);
            return true;
        } /* end if('download' in a) */

        //do iframe dataURL download:
        var f = D.createElement("iframe");
        D.body.appendChild(f);
        f.src = "data:" + (A[2] ? A[2] : "application/octet-stream") + (window.btoa ? ";base64" : "") + "," + (window.btoa ? window.btoa : escape)(strData);
        setTimeout(function() {
            D.body.removeChild(f);
        }, 333);
        return true;
    } /* end download() */

});