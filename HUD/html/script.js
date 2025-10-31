const BRANCH_LEN = 128; // doit matcher le CSS stroke-dasharray

function setBranch(id, pct){
  const el = document.getElementById(id);
  if(!el) return;
  const v = Math.max(0, Math.min(100, Number(pct)||0));
  el.style.strokeDashoffset = String(BRANCH_LEN * (1 - v/100));
}

window.addEventListener('message', (e)=>{
  const d = e.data; if(!d || d.type !== 'update') return;
  setBranch('food', d.hunger);          // vert
  setBranch('water', d.thirst);         // bleu
  setBranch('health-left', d.health);   // rouge
  setBranch('health-right', d.health);
});
