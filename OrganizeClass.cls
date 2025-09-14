//class to trigger events to other system

public class Eventhandlerclass{
public static void a(){
List<CaseChangeEvent>l=(List<CaseChangeEvent>)Trigger.new;
if(l.size()>10)return;
for(Integer i=0;i<l.size();i++){
b(l[i]);
}}
public static void b(CaseChangeEvent e){
try{
EventBus.ChangeEventHeader h=e.ChangeEventHeader;
String r=h.recordIds[0];
Case c=[SELECT Id,ExternalId,ProductId,CaseNumber,RecordType.DeveloperName,Parent.CaseNumber FROM Case WHERE Id=:r];
if(h.changetype=='UPDATE'&&c.RecordType.DeveloperName!='InterA'&&c.RecordType.DeveloperName!='InterB'){
Map<String,Object>m=new Map<String,Object>();
Set<String>s=SyncCaseUtil.getFieldSetFields('Case','SyncFields');
for(String f:h.changedFields){
if(s.contains(f))m.put(f,e.get(f));
}
for(String f:h.nulledFields){
if(s.contains(f))m.put(f,null);
}
if(!m.isEmpty())SyncCaseManager.updateCase(c.ExternalId__c,JSON.serialize(m));
}else if(h.changetype=='CREATE'){
if(c.RecordType.DeveloperName=='InterC'||c.RecordType.DeveloperName=='InterD'){
if(c.ParentId!=null){
Case p=[SELECT Id,CaseNumber,Status,Type,ExternalId,RecordType.DeveloperName,ProductId,Account.Country,Country__c FROM Case WHERE Id=:c.ParentId];
if(p.RecordType.DeveloperName=='InterA'){
if(p.ExternalId__c!=null){
String pe=c.ProductId==null?null:[SELECT ExternalId__c FROM Product2 WHERE Id=:c.ProductId].ExternalId__c;
CaseChangeEventWrapper w=new CaseChangeEventWrapper(e,pe,c);
Map<String,Object>body=new Map<String,Object>{'allOrNone'=>false,'records'=>new List<Map<String,Object>>{new Map<String,Object>{'attributes'=>new Map<String,String>{'type'=>'Case'},'ProductId'=>w.ProductId}}};
SyncCaseManager.createCase(JSON.serialize(body),c.Id);
}}}}}}catch(Exception ex){}}}