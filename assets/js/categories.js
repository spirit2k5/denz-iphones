(()=>{
const legacy=/^iPhone\s+(?:XR|1[1-6])(?=\s|$)/i;
const classify=p=>{if(p.category==='brand-new'&&legacy.test(p.name||''))p={...p,category:'sealed-box',categoryLabel:'Sealed Box',condition:'Still sealed in the box'};if(p.category==='cheaper-options'&&/^100%/.test(p.battery||'')){const notes=String(p.notes||'').replace(/Battery (?:has been )?(?:changed|replaced)(?: with an original battery)?\.?/gi,'').replace(/\s{2,}/g,' ').trim();p={...p,battery:'100%',notes};}return p;};
const label=(category,name)=>{const p=classify({category,name});return {'sealed-box':'Sealed Box','brand-new':'Brand New',preowned:'Pre-Owned','cheaper-options':'Cheaper Options'}[p.category]||category;};
window.DENZ_CATEGORIES={classify,label};
})();
