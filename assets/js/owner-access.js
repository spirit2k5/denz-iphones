(()=>{
const U="https://vpgexijihrozwugqqagy.supabase.co";
const K="sb_publishable_ijbK9YBBaV9j8kyBzwbFOA_iepnbPtC";
const c=supabase.createClient(U,K);
const $=s=>document.querySelector(s);
const out=(el,text,error=false)=>{el.textContent=text||"";el.className=error?"err":"ok"};

async function allowedUser(){
  const {data:{user}}=await c.auth.getUser();
  if(!user?.email)return null;
  const {data,error}=await c.from("denz_admin_emails").select("email").eq("email",user.email).maybeSingle();
  if(error||!data)return null;
  return user;
}
function unlock(user){
  $("#manageStep").style.opacity="1";
  $("#manageStep").style.pointerEvents="auto";
  $("#signOutBtn").hidden=false;
  out($("#authMsg"),"Authorised as "+user.email+".");
}
async function checkExistingSession(){
  const user=await allowedUser();
  if(user)unlock(user);
}
async function authorise(){
  const email=$("#authEmail").value.trim();
  const password=$("#authPassword").value;
  if(!password)return out($("#authMsg"),"Enter the current owner password.",true);
  out($("#authMsg"),"Authorising...");
  const {error}=await c.auth.signInWithPassword({email,password});
  if(error)return out($("#authMsg"),error.message,true);
  const user=await allowedUser();
  if(!user){await c.auth.signOut();return out($("#authMsg"),"This account is not authorised to manage Denz owners.",true)}
  unlock(user);
}
async function saveOwner(){
  const email=$("#targetEmail").value.trim();
  const password=$("#newPassword").value;
  const confirm=$("#confirmPassword").value;
  if(password.length<6)return out($("#ownerMsg"),"Use at least 6 characters.",true);
  if(password!==confirm)return out($("#ownerMsg"),"The two passwords do not match.",true);
  out($("#ownerMsg"),"Updating owner account...");
  const {data,error}=await c.functions.invoke("denz-manage-owner",{body:{email,password}});
  if(error)return out($("#ownerMsg"),error.message||"Could not update owner account.",true);
  if(data?.error)return out($("#ownerMsg"),data.error,true);
  $("#newPassword").value="";
  $("#confirmPassword").value="";
  out($("#ownerMsg"),email+" is confirmed and ready. The password has been set.");
}
$("#authoriseBtn").onclick=authorise;
$("#saveOwnerBtn").onclick=saveOwner;
$("#signOutBtn").onclick=async()=>{await c.auth.signOut();location.reload()};
checkExistingSession();
})();