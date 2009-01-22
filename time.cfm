<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfparam name="url.p" default="">

<cfif session.user.admin>
	<cfset project = application.project.get(projectID=url.p)>
<cfelse>
	<cfset project = application.project.get(session.user.userid,url.p)>
</cfif>

<cfif project.timetrack eq 0 and not session.user.admin>
	<cfoutput><h2>You do not have permission to access time tracking!!!</h2></cfoutput>
	<cfabort>
</cfif>

<cfset projectUsers = application.project.projectUsers(url.p,'0','firstName, lastName')>
<cfset timelines = application.timetrack.get(projectID=url.p)>
<cfif project.tab_billing and project.billing eq 2>
	<cfset rates = application.client.getRates(project.clientID)>
</cfif>
<cfset totalHours = 0>
<cfset totalFee = 0>

<!--- Loads header/footer --->
<cfmodule template="#application.settings.mapping#/tags/layout.cfm" templatename="main" title="#project.name# &raquo; Time Tracking" project="#project.name#" projectid="#url.p#" svnurl="#project.svnurl#">

<cfhtmlhead text="<script type='text/javascript'>
	$(document).ready(function(){
	  	$('.date-pick').datepicker();
	});
</script>">

<cfoutput>
<div id="container">
<cfif project.recordCount>
	<!--- left column --->
	<div class="left full">
		<div class="main">

			<div class="header">
				<span class="rightmenu">
					<a href="##" onclick="$('##report').slideDown();return false;" class="report">Create Report</a>
				</span>
				<h2 class="time">Time Tracking</h2>
			</div>
			<div class="content">
			 	<div class="wrapper">
					
					<form action="timeReport.cfm?p=#url.p#" method="post" class="frm">
					<div id="report" class="p10" style="display:none;">
						<span class="b">
						Show <select name="u">
								<option value="">everyone</option>
								<cfloop query="projectUsers">
									<option value="#userid#"<cfif not compare(session.user.userid,userid)> selected="selected"</cfif>>#firstName# #lastName#</option>
								</cfloop>
							</select>'s hours from 
						<select name="startMonth">
							<cfloop from="1" to="12" index="i">
								<option value="#i#"<cfif Month(Now()) eq i> selected="selected"</cfif>>#Left(MonthAsString(i),3)#</option>
							</cfloop>						
						</select>
						<select name="startDay">
							<cfloop from="1" to="31" index="i">
								<option value="#i#"<cfif Day(Now()) eq i> selected="selected"</cfif>>#i#</option>
							</cfloop>						
						</select>
						<select name="startYear">
							<cfloop from="#Year(Now())#" to="#Year(Now())-5#" index="i" step="-1">
								<option value="#i#"<cfif Year(Now()) eq i> selected="selected"</cfif>>#i#</option>
							</cfloop>						
						</select>
						 to
						<select name="endMonth">
							<cfloop from="1" to="12" index="i">
								<option value="#i#"<cfif Month(Now()) eq i> selected="selected"</cfif>>#Left(MonthAsString(i),3)#</option>
							</cfloop>						
						</select>
						<select name="endDay">
							<cfloop from="1" to="31" index="i">
								<option value="#i#"<cfif Day(Now()) eq i> selected="selected"</cfif>>#i#</option>
							</cfloop>						
						</select>
						<select name="endYear">
							<cfloop from="#Year(Now())#" to="#Year(Now())-5#" index="i" step="-1">
								<option value="#i#"<cfif Year(Now()) eq i> selected="selected"</cfif>>#i#</option>
							</cfloop>						
						</select>
						</span>
						<input type="submit" value="Create Report" /> or <a href="##" onclick="$('##report').slideUp();return false;">Cancel</a>
					</div>
					</form>
					
				 	<table class="clean full" id="time">
					 	<thead>
							<tr>
								<th class="first">Date</th>
								<th>Person</th>
								<th>Hours</th>
								<cfif project.tab_billing and project.billing eq 2>
									<th>Billing Category</th>
									<th>Fee</th>
								</cfif>
								<th>Description</th>
								<cfif project.timetrack eq 2 or session.user.admin><th></th></cfif>
							</tr>
							<cfif project.timetrack eq 2 or session.user.admin>
							<tr class="input">
								<td class="first"><input type="text" name="datestamp" id="datestamp" class="shortest date-pick" /></td>
								<td>
									<select name="userID" id="userid">
										<cfloop query="projectUsers">
										<option value="#userid#"<cfif not compare(session.user.userid,userid)> selected="selected"</cfif>>#firstName# #lastName#</option>
										</cfloop>
									</select>
								</td>
								<td><input type="text" name="hours" id="hrs" class="tiny" /></td>
								<cfif project.tab_billing>
									<td>
										<select name="rateID" id="rateID">
											<option value="">None</option>
											<cfloop query="rates">
												<option value="#rateID#">#category# ($#NumberFormat(rate,"0")#/hr)</option>
											</cfloop>
										</select>
									</td>
									<td>&nbsp;</td>
								<cfelse>
									<input type="hidden" name="rateID" value="" />
								</cfif>
								<td><input type="text" name="description" id="desc" class="short" /></td>
								<td class="tac"><input type="submit" value="Add to log" onclick="add_time_row('#url.p#');" /></td>
							</tr>
							</cfif>
						</thead>
						<tbody>	
						<cfloop query="timelines">
							<cfset thisUserID = userid>
							<tr id="r#replace(timetrackid,'-','','ALL')#">
								<td class="first">#DateFormat(dateStamp,"mmm d, yyyy")#</td>
								<td>#firstName# #lastName#</td>
								<td class="b">#numberFormat(hours,"0.00")#</td>
								<cfif project.tab_billing and project.billing gt 0>
									<td>#category#<cfif compare(category,'')> ($#NumberFormat(rate,"0")#/hr)</cfif></td>
									<td><cfif isNumeric(rate)>$#NumberFormat(rate*hours,"0")#</cfif></td>
								</cfif>
								<td><cfif compare(itemType,'')><span class="catbox #itemtype#">#itemtype#</span> <a href="todos.cfm?p=#projectID###id_#replace(todolistID,'-','','all')#">#task#</a><cfif compare(description,'')> - </cfif></cfif>#description#</td>
								<cfif project.timetrack eq 2 or session.user.admin>
									<td class="tac"><a href="##" onclick="edit_time_row('#projectid#','#timetrackid#','#replace(timetrackid,'-','','ALL')#','#project.tab_billing#','#project.billing#','#project.clientID#')">Edit</a> &nbsp;&nbsp; <a href="##" onclick="delete_time('#projectID#','#timetrackID#','#replace(timetrackid,'-','','ALL')#');" class="delete"></a></td>
								</cfif>
							</tr>
							<cfset totalHours = totalHours + hours>
							<cfif isNumeric(rate)>
								<cfset totalFee = totalFee + (rate*hours)>
							</cfif>
						</cfloop>
						</tbody>
						<tfoot>
							<tr class="last">
								<td colspan="2" class="tar b">TOTAL:&nbsp;&nbsp;&nbsp;</td>
								<td class="b"><span id="totalhours">#NumberFormat(totalHours,"0.00")#</span></td>
								<cfif project.tab_billing and project.billing gt 0>
									<td class="tar b">TOTAL FEE:&nbsp;&nbsp;&nbsp;</td>
									<td class="b">$#NumberFormat(totalFee,"0")#</td>
								</cfif>
								<td colspan="4">&nbsp;</td>
							</tr>
						</tfoot>
					</table>
				 	
				</div>
			</div>
			
		</div>
		<div class="bottom">&nbsp;</div>
		<div class="footer">
			<cfinclude template="footer.cfm">
		</div>	  
	</div>

	<!--- right column --->
	<div class="right">
		
	</div>
<cfelse>
	<div class="alert">Project Not Found.</div>
</cfif>
</div>
</cfoutput>

</cfmodule>

<cfsetting enablecfoutputonly="false">