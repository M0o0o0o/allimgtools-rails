// @cropper/element-shade@2.1.0 downloaded from https://ga.jspm.io/npm:@cropper/element-shade@2.1.0/dist/element-shade.esm.raw.js

import t from"@cropper/element";import{CROPPER_CANVAS as e,CROPPER_SELECTION as i,ACTION_SELECT as n,on as s,EVENT_ACTION_START as h,EVENT_ACTION_END as a,EVENT_CHANGE as o,off as r,isNumber as c,WINDOW as d,CROPPER_SHADE as l}from"@cropper/utils";var $=":host{display:block;height:0;left:0;outline:var(--theme-color) solid 1px;position:relative;top:0;width:0}:host([transparent]){outline-color:transparent}";const p=new WeakMap;class CropperShade extends t{constructor(){super(...arguments);this.$onCanvasActionEnd=null;this.$onCanvasActionStart=null;this.$onSelectionChange=null;this.$style=$;this.x=0;this.y=0;this.width=0;this.height=0;this.slottable=false;this.themeColor="rgba(0, 0, 0, 0.65)"}set $canvas(t){p.set(this,t)}get $canvas(){return p.get(this)}static get observedAttributes(){return super.observedAttributes.concat(["height","width","x","y"])}connectedCallback(){super.connectedCallback();const t=this.closest(this.$getTagNameOf(e));if(t){this.$canvas=t;this.style.position="absolute";const e=t.querySelector(this.$getTagNameOf(i));if(e){this.$onCanvasActionStart=t=>{e.hidden&&t.detail.action===n&&(this.hidden=false)};this.$onCanvasActionEnd=t=>{e.hidden&&t.detail.action===n&&(this.hidden=true)};this.$onSelectionChange=t=>{const{x:i,y:n,width:s,height:h}=t.defaultPrevented?e:t.detail;this.$change(i,n,s,h);(e.hidden||i===0&&n===0&&s===0&&h===0)&&(this.hidden=true)};s(t,h,this.$onCanvasActionStart);s(t,a,this.$onCanvasActionEnd);s(t,o,this.$onSelectionChange)}}this.$render()}disconnectedCallback(){const{$canvas:t}=this;if(t){if(this.$onCanvasActionStart){r(t,h,this.$onCanvasActionStart);this.$onCanvasActionStart=null}if(this.$onCanvasActionEnd){r(t,a,this.$onCanvasActionEnd);this.$onCanvasActionEnd=null}if(this.$onSelectionChange){r(t,o,this.$onSelectionChange);this.$onSelectionChange=null}}super.disconnectedCallback()}
/**
     * Changes the position and/or size of the shade.
     * @param {number} x The new position in the horizontal direction.
     * @param {number} y The new position in the vertical direction.
     * @param {number} [width] The new width.
     * @param {number} [height] The new height.
     * @returns {CropperShade} Returns `this` for chaining.
     */$change(t,e,i=this.width,n=this.height){if(!c(t)||!c(e)||!c(i)||!c(n)||t===this.x&&e===this.y&&i===this.width&&n===this.height)return this;this.hidden&&(this.hidden=false);this.x=t;this.y=e;this.width=i;this.height=n;return this.$render()}
/**
     * Resets the shade to its initial position and size.
     * @returns {CropperShade} Returns `this` for chaining.
     */$reset(){return this.$change(0,0,0,0)}
/**
     * Refreshes the position or size of the shade.
     * @returns {CropperShade} Returns `this` for chaining.
     */$render(){return this.$setStyles({transform:`translate(${this.x}px, ${this.y}px)`,width:this.width,height:this.height,outlineWidth:d.innerWidth})}}CropperShade.$name=l;CropperShade.$version="2.1.0";export{CropperShade as default};

