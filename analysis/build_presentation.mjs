import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const dep='C:/Users/iftek/.cache/codex-runtimes/codex-primary-runtime/dependencies';
const skill='C:/Users/iftek/.codex/plugins/cache/openai-primary-runtime/presentations/26.923.10815/skills/presentations';
const {Presentation,PresentationFile}=await import(pathToFileURL(dep+'/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs'));
const {applyPresentationChartFont,finalizePresentation}=await import(pathToFileURL(skill+'/container_tools/artifact_tool_utils.mjs'));
const root=process.cwd(),build=path.join(root,'analysis/qa/deck');await fs.mkdir(build,{recursive:true});
const p=Presentation.create({slideSize:{width:1280,height:720}});
const font='Calibri';
function text(s,t,x,y,w,h,size=30,bold=false,color='#243746'){
 let z=s.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 z.text=t;z.text.style={typeface:font,fontSize:size,bold,color,autoFit:'none'};return z;
}
function slide(title,notes){let s=p.slides.add();s.background.fill='#FFFFFF';text(s,title,65,45,1150,95,42,true);s.speakerNotes.textFrame.setText(notes);return s;}
function body(s,lines){lines.forEach((t,i)=>text(s,t,80,175+i*112,1120,95,30));}
function chart(s,categories,series,x=80,y=170,w=1100,h=380){
let c=s.charts.add('bar',{position:{left:x,top:y,width:w,height:h},categories,series,
barOptions:{direction:'column',grouping:'clustered'},hasLegend:false,
xAxis:{textStyle:{fontSize:22,fill:'#243746'}},
yAxis:{numberFormatCode:'#,##0.0',textStyle:{fontSize:20,fill:'#243746'}},
dataLabels:{showValue:true,position:'outEnd',numberFormatCode:'#,##0.0',textStyle:{fontSize:23,bold:true,fill:'#243746'}}});
applyPresentationChartFont(c,{fontFamily:font});return c;}
let s=slide('NYC 311 closure delay prediction','ITC 353 Project 1. Supplied NYC311_April2025_RawSample.csv. All analysis executed in base R 4.6.1. AI assistance disclosed in worksheet.');
text(s,'April 2025 sample | ITC 353',80,205,1120,75,34);
text(s,'Evidence for monitoring and follow-up decisions',80,335,1120,100,38);
text(s,'NYC 311 Analytics Student',80,570,1100,60,26);
s=slide('Operational decision and data scope','Sources: supplied overview and R outputs cleaning.csv, split_summary.csv. NYC 311 FAQ https://www.nyc.gov/site/311reporting/faq/faq.page and service request guidance https://portal.311.nyc.gov/article/?kanumber=KA-03116 accessed September 26, 2026. Closure does not establish that an issue was fixed.');
body(s,['Which incoming requests may need extra follow-up?',
'40,000 records; 39,668 have usable closure durations.',
'All are labeled Closed. Still-open requests may be absent.',
'Recorded closure is not proof that the issue was resolved.']);
s=slide('Closure times have a long upper tail','Source: analysis/tables/duration_summary.csv, 39,668 eligible requests. 677 zero-hour durations retained; 2,930 over 30 days. Chart values in hours.');
chart(s,['Median','Mean','95th percentile'],[{name:'Hours',values:[6.6816666667,251.355594,1251.437111],fill:'#287D8E'}]);
text(s,'Hours to recorded closure. 2,930 requests exceed 30 days.',80,590,1120,70,29);
s=slide('Modeling and validation','Source: NYC311_Analysis.R. 70/30 random split, seed 353: 27,767 training and 11,901 validation. Predictors: grouped problem, borough, channel, weekday, hour_sin and hour_cos. Problem levels with fewer than 100 training rows pooled; channel rare fallback to mode. Slow thresholds estimated on training original problem types; fewer than 30 records uses global threshold.');
body(s,['Two models: closure duration and probability of being slow.',
'Slow means above a problem type’s training 75th percentile.',
'70% training / 30% validation; preprocessing uses training only.',
'Predictors use submission context; later outcomes are excluded.']);
s=slide('Log-scale fit does not ensure accurate hours','Source: analysis/tables/linear_metrics.csv, linear_baseline_log.csv and hours_metrics.csv. Validation RMSE log1p-hours 1.308899; training 1.293800. Baseline log RMSE 2.238796. Predictive R-squared .6581893. Hour predictions use Duan smearing estimated from training residuals. Hour MAE 316.65 versus baseline 392.31.');
chart(s,['Mean baseline','Converted linear model'],[{name:'Hour RMSE',values:[970.9672,1373.1778],fill:'#287D8E'}]);
text(s,'Hour RMSE is worse than the baseline. Avoid completion-time promises.',80,585,1120,75,28);
s=slide('Slow-request detection is weak','Source: analysis/tables/classification_metrics.csv and model_extras.csv. Validation n=11,901; cutoff=.25; TN=4997, FP=3789, FN=1550, TP=1565. AUC=.554211. At .50: no flags, accuracy=.7382573 and recall=0. Cutoff .25 chosen as screening assumption, not tuned on validation.');
chart(s,['Recall %','Precision %','Requests flagged %'],[{name:'Percent',values:[50.24077,29.23048,44.98782],fill:'#287D8E'}]);
text(s,'About half of slow requests are missed; most flags are false alerts.',80,585,1120,75,28);
s=slide('One cutoff creates uneven borough workloads','Source: analysis/tables/optional_borough_monitor.csv. Validation flag rates at .25. Group case mix and calibration may contribute; chart does not establish causality or discrimination. Bronx n=2288; Brooklyn=3748; Manhattan=2480; Queens=2958; Staten Island=427.');
chart(s,['Bronx','Brooklyn','Manhattan','Queens','Staten Island'],[{name:'Flag rate %',values:[99.43182,20.9445,37.37903,46.04462,1.17096],fill:'#287D8E'}]);
text(s,'Flag rates in validation, %. Review subgroup errors before any pilot.',80,585,1120,75,28);
s=slide('Recommendation for city operations','Recommendation derived from weak AUC, low precision, hour-scale errors, sampling limitations, and borough monitoring. No operational impact has been demonstrated. This is a classroom analysis, not an endorsed or deployed NYC system.');
body(s,['Do not automate prioritization with the current classifier.',
'Investigate long closure workflows and missing timestamps.',
'Test later-month data, including requests that remain open.',
'If piloted, use staff review and explicit limits on alert workload.']);
s=slide('Limits and next evaluation','Sources: supplied sample and analysis. Unknown sampling method; April boundary days underrepresented. Random split may not isolate related requests. Definition is relative, not an official SLA. Tool use: base R for all statistics; AI-assisted code and reporting; independent metric checks performed.');
body(s,['One month and an unknown sampling method limit generalization.',
'Relative slow status is not an official service deadline.',
'Compare against simple rules and review errors by problem and borough.',
'Urgency and service obligations must remain ahead of model scores.']);
const candidate=path.join(build,'candidate.pptx');await (await PresentationFile.exportPptx(p)).save(candidate);
for(let i=0;i<p.slides.items.length;i++){
 const im=await p.export({slide:p.slides.items[i],format:'png',scale:1});
 await fs.writeFile(path.join(build,`slide-${i+1}.png`),new Uint8Array(await im.arrayBuffer()));
}
await fs.mkdir(path.join(root,'analysis/deliverable'),{recursive:true});
const result=await finalizePresentation({workspaceDir:root,candidatePath:candidate,
 finalPath:path.join(root,'analysis/deliverable/NYC311_Business_Presentation.pptx'),pythonExecutable:dep+'/python/python.exe',
 integrityValidatorPath:skill+'/container_tools/inspect_presentation_package_integrity.py',
 layoutValidatorPath:skill+'/container_tools/inspect_presentation_layout_geometry.py',
 layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit'],
 requiredNativeChartOwnerSlides:[3,5,6,7],materializeLiteralChartWorkbooks:true,
 fontPolicy:{basis:'design',families:[font]},verifyArtifactToolImport:true,
 receiptPath:path.join(build,'validation.json')});
console.log(JSON.stringify(result));
await fs.copyFile(path.join(root,'analysis/deliverable/NYC311_Business_Presentation.pptx'),path.join(root,'NYC311_Business_Presentation.pptx'));
