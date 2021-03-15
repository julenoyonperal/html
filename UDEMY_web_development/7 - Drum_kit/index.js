
var loop_number = document.querySelectorAll(".drum").length;

for( var i=0; i< loop_number; i++){

  document.querySelectorAll(".drum")[i].addEventListener("click", function(){

    // this.style.color = "yellow";

    // var file = 'sounds/tom' + i +'.mp3';
    // var audio = new Audio(file);
    // audio.play();
    // alert("I got click" + i);


  console.log(this);
    var button_inner_html = this.innerHTML;

          button_animation(button_inner_html);

    switch (button_inner_html) {

      case "z":
      var tom1 = new Audio("sounds/tom1.mp3");
      tom1.play();
      break;

      case "a":
      var tom1 = new Audio("sounds/tom2.mp3");
      tom1.play();
      break;
      case "s":
      var tom1 = new Audio("sounds/tom3.mp3");
      tom1.play();
      break;
      case "d":
      var tom1 = new Audio("sounds/tom4.mp3");
      tom1.play();
      break;
      case "j":
      var tom1 = new Audio("sounds/tom5.mp3");
      tom1.play();
      break;
      case "k":
      var tom1 = new Audio("sounds/tom6.mp3");
      tom1.play();
      break;
      case "l":
      var tom1 = new Audio("sounds/tom7.mp3");
      tom1.play();
      break;

      default:

    }

  });
}

document.addEventListener("keypress", function(id){

  var button_inner_html = id.key;

  console.log(id);
  console.log(this.innerHTML);
  button_animation(button_inner_html);
  switch (button_inner_html) {

    case "z":
    var tom1 = new Audio("sounds/tom1.mp3");
    tom1.play();
    break;

    case "a":
    var tom1 = new Audio("sounds/tom2.mp3");
    tom1.play();
    break;
    case "s":
    var tom1 = new Audio("sounds/tom3.mp3");
    tom1.play();
    break;
    case "d":
    var tom1 = new Audio("sounds/tom4.mp3");
    tom1.play();
    break;
    case "j":
    var tom1 = new Audio("sounds/tom5.mp3");
    tom1.play();
    break;
    case "k":
    var tom1 = new Audio("sounds/tom6.mp3");
    tom1.play();
    break;
    case "l":
    var tom1 = new Audio("sounds/tom7.mp3");
    tom1.play();
    break;

    default:

  }

});


function button_animation(current_key){

  var active_button = document.querySelector("."+current_key);

  active_button.classList.add("pressed");

  setTimeout(function () {
          active_button.classList.remove("pressed");
      }, 100);



}
