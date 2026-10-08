(()=>{
const legacy=/^iPhone\s+(?:XR|1[1-5])(?=\s|$)/i;
const classify=p=>p.category==='brand-new'&&legacy.test(p.name||'')?{...p,category:'sealed-box',categoryLabel:'Sealed Box',condition:'Still sealed in the box'}:p;
const label=(category,name)=>{const p=classify({category,name});return {'sealed-box':'Sealed Box','brand-new':'Brand New',preowned:'Pre-Owned','cheaper-options':'Cheaper Options'}[p.category]||category;};
window.DENZ_CATEGORIES={classify,label};
})();
