import { current, improved, problems, members } from './content.js';

function renderFlow(id, steps) {
 document.querySelector(id).innerHTML = steps.map(([actor,title,description,issue],index)=>`<li class="flow-step ${issue?'has-issue':''}"><span class="step-number" aria-hidden="true">${String(index+1).padStart(2,'0')}</span><div class="step-content"><div class="step-top"><span class="actor">${actor}</span></div><h4>${title}</h4><p>${description}</p>${issue?`<aside class="bottleneck"><strong>Process risk</strong>${issue}</aside>`:''}</div></li>`).join('');
}
renderFlow('#current-flow',current);
renderFlow('#improved-flow',improved);
document.querySelector('#problem-list').innerHTML=problems.map(([title,description,people,solution],i)=>`<details class="problem" ${i===0?'open':''}><summary><span class="problem-number">0${i+1}</span><h3>${title}</h3><span class="disclosure-icon" aria-hidden="true">+</span></summary><div class="problem-content"><p>${description}</p><div><span class="eyebrow">WHO IS AFFECTED</span><p>${people}</p></div><div><span class="eyebrow">PROPOSED RESPONSE</span><p>${solution}</p></div></div></details>`).join('');
document.querySelector('#members').innerHTML=members.map(([letter,name,matric,role,note])=>`<article class="member"><div class="member-letter" aria-hidden="true">${letter}</div><span class="eyebrow">STUDENT ${letter}${note?' / GROUP LEADER':''}</span><h3>${name}</h3><p class="matric">${matric}</p><p class="member-role">${role}</p></article>`).join('');
const viewButtons=[...document.querySelectorAll('[data-view] button,button[data-view]')];
viewButtons.forEach(button=>button.addEventListener('click',()=>{document.querySelector('.flow-columns').dataset.view=button.dataset.view;viewButtons.forEach(item=>item.setAttribute('aria-pressed',String(item===button)));}));
const menu=document.querySelector('.menu-button'), nav=document.querySelector('#navigation');
menu.addEventListener('click',()=>{const open=menu.getAttribute('aria-expanded')!=='true';menu.setAttribute('aria-expanded',String(open));nav.classList.toggle('is-open',open);});
nav.addEventListener('click',event=>{if(event.target.closest('a')){menu.setAttribute('aria-expanded','false');nav.classList.remove('is-open');}});
document.addEventListener('keydown',event=>{if(event.key==='Escape'&&nav.classList.contains('is-open')){menu.setAttribute('aria-expanded','false');nav.classList.remove('is-open');menu.focus();}});
document.querySelector('.print-button').addEventListener('click',()=>window.print());
const highlight=document.querySelector('.highlight-button');
highlight.addEventListener('click',()=>{const active=highlight.getAttribute('aria-pressed')!=='true';highlight.setAttribute('aria-pressed',String(active));highlight.textContent=`Sequence words: ${active?'on':'off'}`;document.querySelector('.prose-flow').classList.toggle('no-highlight',!active);});
const observer=new IntersectionObserver(entries=>{for(const entry of entries){if(entry.isIntersecting){nav.querySelectorAll('a').forEach(a=>{if(a.hash===`#${entry.target.id}`)a.setAttribute('aria-current','location');else a.removeAttribute('aria-current');});}}},{rootMargin:'-15% 0px -65% 0px'});
['a','b','c','f','i'].forEach(id=>observer.observe(document.getElementById(id)));

const footer = document.querySelector('.site-footer');
const footerObserver = new IntersectionObserver(([entry]) => {
 if (entry.isIntersecting) { footer.classList.add('is-visible'); footerObserver.disconnect(); }
}, { threshold: 0.15 });
footerObserver.observe(footer);
// A footer link must reveal the improved figure if the current-only view is selected.
document.querySelector('.footer-nav a[href="#e"]').addEventListener('click', () => {
 if (document.querySelector('.flow-columns').dataset.view === 'current') {
  document.querySelector('button[data-view="improved"]').click();
 }
});
