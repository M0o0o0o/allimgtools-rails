// @cropper/element-image@2.1.0 downloaded from https://ga.jspm.io/npm:@cropper/element-image@2.1.0/dist/element-image.esm.raw.js

import t from"@cropper/element";import{CROPPER_CANVAS as s,on as i,EVENT_ACTION_START as e,EVENT_ACTION_END as a,EVENT_ACTION as n,EVENT_LOAD as o,off as r,ACTION_TRANSFORM as h,ACTION_ROTATE as c,ACTION_SCALE as l,ACTION_NONE as $,CROPPER_SELECTION as d,ACTION_MOVE as m,EVENT_ERROR as g,once as b,isFunction as f,isNumber as u,toAngleInRadian as C,multiplyMatrices as v,EVENT_TRANSFORM as p,CROPPER_IMAGE as k}from"@cropper/utils";var y=":host{display:inline-block}img{display:block;height:100%;max-height:none!important;max-width:none!important;min-height:0!important;min-width:0!important;width:100%}";const A=new WeakMap;const x=["alt","crossorigin","decoding","elementtiming","fetchpriority","loading","referrerpolicy","sizes","src","srcset"];class CropperImage extends t{constructor(){super(...arguments);this.$matrix=[1,0,0,1,0,0];this.$onLoad=null;this.$onCanvasAction=null;this.$onCanvasActionEnd=null;this.$onCanvasActionStart=null;this.$actionStartTarget=null;this.$style=y;this.$image=new Image;this.initialCenterSize="contain";this.rotatable=false;this.scalable=false;this.skewable=false;this.slottable=false;this.translatable=false;this.alt="";this.crossorigin="";this.decoding="";this.elementtiming="";this.fetchpriority="";this.loading="";this.referrerpolicy="";this.sizes="";this.src="";this.srcset=""}set $canvas(t){A.set(this,t)}get $canvas(){return A.get(this)}static get observedAttributes(){return super.observedAttributes.concat(x,["initial-center-size","rotatable","scalable","skewable","translatable"])}attributeChangedCallback(t,s,i){if(!Object.is(i,s)){super.attributeChangedCallback(t,s,i);x.includes(t)&&this.$image.setAttribute(t,i)}}$propertyChangedCallback(t,s,i){if(!Object.is(i,s)){super.$propertyChangedCallback(t,s,i);switch(t){case"initialCenterSize":this.$nextTick((()=>{this.$center(i)}));break}}}connectedCallback(){super.connectedCallback();const{$image:t}=this;const r=this.closest(this.$getTagNameOf(s));if(r){this.$canvas=r;this.$setStyles({display:"block",position:"absolute"});this.$onCanvasActionStart=t=>{var s,i;this.$actionStartTarget=(i=(s=t.detail)===null||s===void 0?void 0:s.relatedEvent)===null||i===void 0?void 0:i.target};this.$onCanvasActionEnd=()=>{this.$actionStartTarget=null};this.$onCanvasAction=this.$handleAction.bind(this);i(r,e,this.$onCanvasActionStart);i(r,a,this.$onCanvasActionEnd);i(r,n,this.$onCanvasAction)}this.$onLoad=this.$handleLoad.bind(this);i(t,o,this.$onLoad);this.$getShadowRoot().appendChild(t)}disconnectedCallback(){const{$image:t,$canvas:s}=this;if(s){if(this.$onCanvasActionStart){r(s,e,this.$onCanvasActionStart);this.$onCanvasActionStart=null}if(this.$onCanvasActionEnd){r(s,a,this.$onCanvasActionEnd);this.$onCanvasActionEnd=null}if(this.$onCanvasAction){r(s,n,this.$onCanvasAction);this.$onCanvasAction=null}}if(t&&this.$onLoad){r(t,o,this.$onLoad);this.$onLoad=null}this.$getShadowRoot().removeChild(t);super.disconnectedCallback()}$handleLoad(){const{$image:t}=this;this.$setStyles({width:t.naturalWidth,height:t.naturalHeight});this.$canvas&&this.$center(this.initialCenterSize)}$handleAction(t){if(this.hidden||!(this.rotatable||this.scalable||this.translatable))return;const{$canvas:s}=this;const{detail:i}=t;if(i){const{relatedEvent:t}=i;let{action:e}=i;e!==h||this.rotatable&&this.scalable||(e=this.rotatable?c:this.scalable?l:$);switch(e){case m:if(this.translatable){let e=null;t&&(e=t.target.closest(this.$getTagNameOf(d)));e||(e=s.querySelector(this.$getTagNameOf(d)));e&&e.multiple&&!e.active&&(e=s.querySelector(`${this.$getTagNameOf(d)}[active]`));e&&!e.hidden&&e.movable&&!e.dynamic&&this.$actionStartTarget&&e.contains(this.$actionStartTarget)||this.$move(i.endX-i.startX,i.endY-i.startY)}break;case c:if(this.rotatable)if(t){const{x:s,y:e}=this.getBoundingClientRect();this.$rotate(i.rotate,t.clientX-s,t.clientY-e)}else this.$rotate(i.rotate);break;case l:if(this.scalable)if(t){const s=t.target.closest(this.$getTagNameOf(d));if(!s||!s.zoomable||s.zoomable&&s.dynamic){const{x:s,y:e}=this.getBoundingClientRect();this.$zoom(i.scale,t.clientX-s,t.clientY-e)}}else this.$zoom(i.scale);break;case h:if(this.rotatable&&this.scalable){const{rotate:s}=i;let{scale:e}=i;e<0?e=1/(1-e):e+=1;const a=Math.cos(s);const n=Math.sin(s);const[o,r,h,c]=[a*e,n*e,-n*e,a*e];if(t){const s=this.getBoundingClientRect();const i=t.clientX-s.x;const e=t.clientY-s.y;const[a,n,l,$]=this.$matrix;const d=s.width/2;const m=s.height/2;const g=i-d;const b=e-m;const f=(g*$-l*b)/(a*$-l*n);const u=(b*a-n*g)/(a*$-l*n);this.$transform(o,r,h,c,f*(1-o)+u*h,u*(1-c)+f*r)}else this.$transform(o,r,h,c,0,0)}break}}}
/**
     * Defers the callback to execute after successfully loading the image.
     * @param {Function} [callback] The callback to execute after successfully loading the image.
     * @returns {Promise} Returns a promise that resolves to the image element.
     */$ready(t){const{$image:s}=this;const i=new Promise(((t,i)=>{const e=new Error("Failed to load the image source");if(s.complete)s.naturalWidth>0&&s.naturalHeight>0?t(s):i(e);else{const a=()=>{r(s,g,n);setTimeout((()=>{t(s)}))};const n=()=>{r(s,o,a);i(e)};b(s,o,a);b(s,g,n)}}));f(t)&&i.then((s=>{t(s);return s}));return i}
/**
     * Aligns the image to the center of its parent element.
     * @param {string} [size] The size of the image.
     * @returns {CropperImage} Returns `this` for chaining.
     */$center(t){const{parentElement:s}=this;if(!s)return this;const i=s.getBoundingClientRect();const e=i.width;const a=i.height;const{x:n,y:o,width:r,height:h}=this.getBoundingClientRect();const c=n+r/2;const l=o+h/2;const $=i.x+e/2;const d=i.y+a/2;this.$move($-c,d-l);if(t&&(r!==e||h!==a)){const s=e/r;const i=a/h;switch(t){case"cover":this.$scale(Math.max(s,i));break;case"contain":this.$scale(Math.min(s,i));break}}return this}
/**
     * Moves the image.
     * @param {number} x The moving distance in the horizontal direction.
     * @param {number} [y] The moving distance in the vertical direction.
     * @returns {CropperImage} Returns `this` for chaining.
     */$move(t,s=t){if(this.translatable&&u(t)&&u(s)){const[i,e,a,n]=this.$matrix;const o=(t*n-a*s)/(i*n-a*e);const r=(s*i-e*t)/(i*n-a*e);this.$translate(o,r)}return this}
/**
     * Moves the image to a specific position.
     * @param {number} x The new position in the horizontal direction.
     * @param {number} [y] The new position in the vertical direction.
     * @returns {CropperImage} Returns `this` for chaining.
     */$moveTo(t,s=t){if(this.translatable&&u(t)&&u(s)){const[i,e,a,n]=this.$matrix;const o=(t*n-a*s)/(i*n-a*e);const r=(s*i-e*t)/(i*n-a*e);this.$setTransform(i,e,a,n,o,r)}return this}
/**
     * Rotates the image.
     * {@link https://developer.mozilla.org/en-US/docs/Web/CSS/transform-function/rotate}
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/rotate}
     * @param {number|string} angle The rotation angle (in radians).
     * @param {number} [x] The rotation origin in the horizontal, defaults to the center of the image.
     * @param {number} [y] The rotation origin in the vertical, defaults to the center of the image.
     * @returns {CropperImage} Returns `this` for chaining.
     */$rotate(t,s,i){if(this.rotatable){const e=C(t);const a=Math.cos(e);const n=Math.sin(e);const[o,r,h,c]=[a,n,-n,a];if(u(s)&&u(i)){const[t,e,a,n]=this.$matrix;const{width:l,height:$}=this.getBoundingClientRect();const d=l/2;const m=$/2;const g=s-d;const b=i-m;const f=(g*n-a*b)/(t*n-a*e);const u=(b*t-e*g)/(t*n-a*e);this.$transform(o,r,h,c,f*(1-o)-u*h,u*(1-c)-f*r)}else this.$transform(o,r,h,c,0,0)}return this}
/**
     * Zooms the image.
     * @param {number} scale The zoom factor. Positive numbers for zooming in, and negative numbers for zooming out.
     * @param {number} [x] The zoom origin in the horizontal, defaults to the center of the image.
     * @param {number} [y] The zoom origin in the vertical, defaults to the center of the image.
     * @returns {CropperImage} Returns `this` for chaining.
     */$zoom(t,s,i){if(!this.scalable||t===0)return this;t<0?t=1/(1-t):t+=1;if(u(s)&&u(i)){const[e,a,n,o]=this.$matrix;const{width:r,height:h}=this.getBoundingClientRect();const c=r/2;const l=h/2;const $=s-c;const d=i-l;const m=($*o-n*d)/(e*o-n*a);const g=(d*e-a*$)/(e*o-n*a);this.$transform(t,0,0,t,m*(1-t),g*(1-t))}else this.$scale(t);return this}
/**
     * Scales the image.
     * {@link https://developer.mozilla.org/en-US/docs/Web/CSS/transform-function/scale}
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/scale}
     * @param {number} x The scaling factor in the horizontal direction.
     * @param {number} [y] The scaling factor in the vertical direction.
     * @returns {CropperImage} Returns `this` for chaining.
     */$scale(t,s=t){this.scalable&&this.$transform(t,0,0,s,0,0);return this}
/**
     * Skews the image.
     * {@link https://developer.mozilla.org/en-US/docs/Web/CSS/transform-function/skew}
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform}
     * @param {number|string} x The skewing angle in the horizontal direction.
     * @param {number|string} [y] The skewing angle in the vertical direction.
     * @returns {CropperImage} Returns `this` for chaining.
     */$skew(t,s=0){if(this.skewable){const i=C(t);const e=C(s);this.$transform(1,Math.tan(e),Math.tan(i),1,0,0)}return this}
/**
     * Translates the image.
     * {@link https://developer.mozilla.org/en-US/docs/Web/CSS/transform-function/translate}
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/translate}
     * @param {number} x The translating distance in the horizontal direction.
     * @param {number} [y] The translating distance in the vertical direction.
     * @returns {CropperImage} Returns `this` for chaining.
     */$translate(t,s=t){this.translatable&&u(t)&&u(s)&&this.$transform(1,0,0,1,t,s);return this}
/**
     * Transforms the image.
     * {@link https://developer.mozilla.org/en-US/docs/Web/CSS/transform-function/matrix}
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/transform}
     * @param {number} a The scaling factor in the horizontal direction.
     * @param {number} b The skewing angle in the vertical direction.
     * @param {number} c The skewing angle in the horizontal direction.
     * @param {number} d The scaling factor in the vertical direction.
     * @param {number} e The translating distance in the horizontal direction.
     * @param {number} f The translating distance in the vertical direction.
     * @returns {CropperImage} Returns `this` for chaining.
     */$transform(t,s,i,e,a,n){return u(t)&&u(s)&&u(i)&&u(e)&&u(a)&&u(n)?this.$setTransform(v(this.$matrix,[t,s,i,e,a,n])):this}
/**
     * Resets (overrides) the current transform to the specific identity matrix.
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setTransform}
     * @param {number|Array} a The scaling factor in the horizontal direction.
     * @param {number} b The skewing angle in the vertical direction.
     * @param {number} c The skewing angle in the horizontal direction.
     * @param {number} d The scaling factor in the vertical direction.
     * @param {number} e The translating distance in the horizontal direction.
     * @param {number} f The translating distance in the vertical direction.
     * @returns {CropperImage} Returns `this` for chaining.
     */$setTransform(t,s,i,e,a,n){if(this.rotatable||this.scalable||this.skewable||this.translatable){Array.isArray(t)&&([t,s,i,e,a,n]=t);if(u(t)&&u(s)&&u(i)&&u(e)&&u(a)&&u(n)){const o=[...this.$matrix];const r=[t,s,i,e,a,n];if(this.$emit(p,{matrix:r,oldMatrix:o})===false)return this;this.$matrix=r;this.style.transform=`matrix(${r.join(", ")})`}}return this}
/**
     * Retrieves the current transformation matrix being applied to the element.
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/getTransform}
     * @returns {Array} Returns the readonly transformation matrix.
     */$getTransform(){return this.$matrix.slice()}
/**
     * Resets the current transform to the initial identity matrix.
     * {@link https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/resetTransform}
     * @returns {CropperImage} Returns `this` for chaining.
     */$resetTransform(){return this.$setTransform([1,0,0,1,0,0])}}CropperImage.$name=k;CropperImage.$version="2.1.0";export{CropperImage as default};

