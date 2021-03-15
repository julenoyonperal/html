function myFunction(id) {
    var test;
    test = document.getElementById(id).value;
    alert(test);
    document.getElementById("demo").innerHTML = "The value of the value attribute was changed. Try to submit the form again.";
}

function print_text() {
    var kuku = document.getElementById("demo").value;
    document.getElementById("demo_final").innerHTML = [kuku, kuku];
}


function change_color() {
    var color = document.getElementById('fname').value;
    document.body.style.background = color;
}



function update_text_input(val) {
    document.getElementById('textInput').value = val;
}


function update_text_input_2(val) {
    document.getElementById('textInput2').value = val;
}

function sum_ranges() {
    var v1 = document.getElementById('textInput2').value;
    var v2 = document.getElementById('textInput').value;
    var total = parseInt(v1) + parseInt(v2);
    document.getElementById("total_sum").innerHTML = total;
}

function sum_ranges_2() {
    var v1 = document.getElementById('textInput2').value;
    var v2 = document.getElementById('textInput').value;
    var total = parseInt(v1) + parseInt(v2);
    document.getElementById("total_sum_2").value = total;
}