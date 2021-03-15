var random_number = Math.floor(Math.random()*6) + 1 ;

var random_dice_image = "dice" + random_number +".png";

var random_image_source = "images/" + random_dice_image;

var image1 = document.querySelectorAll("img")[0];

image1.setAttribute("src",random_image_source );



var random_number_2 = Math.floor(Math.random()*6) + 1 ;

var random_dice_image_2 = "dice" + random_number_2 +".png";

var random_image_source_2 = "images/" + random_dice_image_2;

document.querySelectorAll("img")[1].setAttribute("src",random_image_source_2 );



if(random_number > random_number_2){
  document.querySelector("h1").innerHTML = "Play 1 Wins!";
} else if(random_number < random_number_2){
  document.querySelector("h1").innerHTML = "Play 2 Wins!";
}else{
  document.querySelector("h1").innerHTML = "Draw!";
}
