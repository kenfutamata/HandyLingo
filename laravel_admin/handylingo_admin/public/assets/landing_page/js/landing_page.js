const menuBtn = document.getElementById('mobile-menu-button');
const mobileMenu = document.getElementById('mobile-menu');

menuBtn.addEventListener('click', () => {
    mobileMenu.classList.toggle('hidden');
});

function toggleMenu() {
    const menu = document.getElementById('mobile-menu');
    menu.classList.toggle('hidden');
}

setTimeout(() => {
    const notif = document.getElementById('notification-bar');
    if (notif) notif.style.opacity = '0';
}, 2500);
setTimeout(() => {
    const notif = document.getElementById('notification-bar');
    if (notif) notif.style.display = 'none';
}, 3000);

function openStarsSection(){
    const feedback_type = document.getElementById('feedback_type');
    if(feedback_type.value === "App Feedback"){
        document.getElementById('stars_section').style.display = "block";
    } else {
        document.getElementById('stars_section').style.display = "none";
    }
}