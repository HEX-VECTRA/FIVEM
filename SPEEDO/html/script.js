let visible = false;

function setPct(el, pct){
  const v = Math.max(0, Math.min(100, Number(pct)||0));
  el.style.height = v + '%';
}

window.addEventListener('message', (e)=>{
  const d = e.data;
  if(!d || !d.type) return;

  if(d.type === 'show'){
    visible = !!d.show;
    document.getElementById('speedV').style.display = visible ? 'flex' : 'none';
  }

  if(d.type === 'update' && visible){
    setPct(document.getElementById('bar-fuel'), d.fuel);
    setPct(document.getElementById('bar-rpm'), d.rpm);

    const speedPct = Math.max(0, Math.min(100, ((Number(d.kmh)||0)/240)*100));
    setPct(document.getElementById('bar-speed'), speedPct);
    setPct(document.getElementById('bar-health'), d.health);

    document.getElementById('kmh').textContent = (Number(d.kmh)||0);
    document.getElementById('odo').textContent = (Number(d.odokm)||0).toFixed(1)+' km';
  }
});
