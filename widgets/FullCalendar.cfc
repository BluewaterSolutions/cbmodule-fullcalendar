<!--- 
********************************************************************************
Copyright 2017 Full Calendar by Mark Skelton and Computer Know How, LLC
www.compknowhow.com
********************************************************************************

Author:  Mark Skelton
Description:  A widget that executes the ContentBox Full Calendar Module to render a Full Calendar on the target page.
--->

<cfcomponent extends="contentbox.models.ui.BaseWidget" singleton>
	<cfproperty name="settingService" inject="id:settingService@cb">
	<cfproperty name="CalendarService" inject="entityService:Calendar">
	<cfproperty name="EventService" inject="entityService:Event">

	<cffunction name="init" returntype="FullCalendar">
		<cfargument name="controller" required="true">
		<!--- super init --->
		<cfset super.init(controller)>

		<!--- Widget Properties --->
		<cfset setName("FullCalendar")>
		<cfset setVersion("1.1")>
		<cfset setDescription("A widget that renders a full calendar")>
		<cfset setAuthor("Computer Know How, LLC")>
		<cfset setAuthorURL("http://www.compknowhow.com")>
		<cfset setCategory( "Misc" )>
		<cfset setIcon( "calendar" )>
		<cfreturn this>
	</cffunction>

	<cffunction name="renderIt" returntype="any">
		<cfargument name="calendars" required="true" hint="A comma seperated list of calendars.">

		<cfset var settings = getFullCalendarSettings()>
		<cfset var outputString = "">

		<cfsavecontent variable="outputString">
			<cfoutput>
				<style>
					.fc-button {
						line-height: 20px;
						text-transform: none;
					}
					.fc-button:focus {
						outline: 0;
					}
					.fc-state-hover {
						background-color: ##e6e6e6 !important;
					}
					.fc-state-disabled:hover, .fc-state-active:hover {
						background-color: ##e6e6e6 !important;
					}
					.fc-content:hover {
						cursor: pointer;
					}

					.fullCalendarLegend {
						margin-top: 20px;
					}
					.fullCalendarLegend legend {
						border-bottom-color: ##c1c0c0;
					}
					.fullCalendarLegendItem {
						display: inline-block;
						padding: 5px 10px;
						margin-right: 15px;
						border-radius: 3px;
						vertical-align: middle;
						margin-bottom: 15px;
					}
					.fullCalendarLegendItem label {
						margin: 0;
						display: inline-block;
					}
					.fullCalendarLegendItem label input{
						height: 19px;
						margin-right: 10px;
						margin-top: 0;
					}

					.gCalDownload {
						margin-left: 5px;
					}
					.gCalDownload:hover {
						cursor: pointer;
						text-decoration: none;
					}
					.gCalDownload i {
						vertical-align: middle;
					}
					@media (max-width: 992px) {
						.fc-center {
							float: none !important;
							clear: both;
							display: block !important;
							margin-bottom: 15px;
						}
						.fc-left {
							margin-bottom: 15px;
						}
					}
					@media (max-width: 600px) {
						.fc-left, .fc-right, .fc-center {
							float: none !important;
							clear: both;
							display: block !important;
							margin-bottom: 10px;
						}
					}
				</style>
				<div id="calendar"></div>

				<script>
					onload = function() {
						$('##calendar').fullCalendar({
							header: {
								left: '#settings.nextPrevButtons eq true ? 'prev,next' : ''# #settings.todayButton eq true ? 'today' : ''# #settings.refreshButton eq true ? 'refreshButton' : ''#',
								center: '#settings.dateButton eq true ? 'title' : ''#',
								right: '#settings.monthButton eq true ? 'month' : ''#,#settings.weekButton eq true ? 'agendaWeek' : ''#,#settings.dayButton eq true ? 'agendaDay' : ''#,#settings.agendaButton eq true ? 'listWeek' : ''#'
							},
							buttonText: {
								today: 'Today',
								month: 'Month',
								week: 'Week',
								day: 'Day',
								list: 'Agenda'
							},
							defaultView: '#settings.defaultView#',
							<cfif settings.refreshButton>
								customButtons: {
									refreshButton: {
										text: 'Refresh',
										click: function() {
											$('##calendar').fullCalendar('refetchEvents');
										}
									}
								},
							</cfif>
							googleCalendarApiKey: '#settings.googleCalendarApiKey#',
							eventSources: [
								<cfloop list="#arguments.calendars#" index="i">
									<cfset calendar = calendarService.findWhere({slug=i})>
									<cfset calendarType = !isNull(calendar) ? calendar.getCalendarType() : ''>

									<cfif calendarType eq "google">
										{
											googleCalendarId: '#calendar.getGoogleCalendarID()#',
											className: 'fcal-#calendar.getCalendarID()# tooltipster-tooltip',
											<cfif calendar.getGoogleCalendarApiKey() neq "">
												googleCalendarApiKey: '#calendar.getGoogleCalendarApiKey()#',
											</cfif>
											<cfif calendar.getEventColor() neq "">
												color: '#calendar.getEventColor()#',
											</cfif>
											<cfif calendar.getEventTextColor() neq "">
												textColor: '#calendar.getEventTextColor()#',
											</cfif>
										},
									<cfelseif calendarType eq "contentbox">
										<cfset calendarEvents = calendar.getEvents()>
										[
											<cfloop array="#calendarEvents#" index="calendarEvent">
												{
													title: '#reReplace(calendarEvent.getName(), "\'", "\'", "all")#',
													description: '#reReplace(calendarEvent.getDescription(), "\'", "\'", "all")#',
													start: '#dateFormat(calendarEvent.getStartTime(), "yyyy-mm-dd")#T#timeFormat(calendarEvent.getStartTime(), "hh:mm:ss")#',
													end: '#dateFormat(calendarEvent.getEndTime(), "yyyy-mm-dd")#T#timeFormat(calendarEvent.getEndTime(), "hh:mm:ss")#',
													allDay: #calendarEvent.getAllDay() eq 1 ? true : false#,
													color: '#calendar.getEventColor()#',
													textColor: '#calendar.getEventTextColor()#',
													className: 'fcal-#calendar.getCalendarID()#'
												},
											</cfloop>
										],
									</cfif>
								</cfloop>
							],
							eventColor: '#settings.eventColor#',
							eventTextColor: '#settings.eventTextColor#',
							navLinks: #settings.navLinks ? true : false#,
							nowIndicator: #settings.nowIndicator ? true : false#,
							eventClick: function(event) {
								if (#settings.openGCalEvents# == true && event.url) {
									#settings.newTab eq true ? 'window.open(event.url);' : 'window.location.href(event.url);'#
								}
									return false;
							},
							eventAfterRender: function(event, element, view) {
								var content = '';
								content += '<h3 style="margin-top: 0;">' + event.title + '</h3>';
								if (event.description) {
									content += '<p style="word-wrap: break-word;"><b>Description:</b> ' + event.description + '</p>';
								}
								if (event.allDay) {
									content += '<p><b>Start:</b> ' + event.start.format('MMMM Do YYYY')  + '</p>';
									if (!event.end) end = event.start;
									else end = event.end;

									content += '<p><b>End:</b> ' + end.format('MMMM Do YYYY')  + '</p>';
								} else {
									content += '<p><b>Start:</b> ' + event.start.format('MMMM Do YYYY, h:mm A')  + '</p>';
									content += '<p><b>End:</b> ' + event.end.format('MMMM Do YYYY, h:mm A')  + '</p>';
								}
								$(element).tooltipster({
									content: content,
									contentAsHTML: true,
									maxWidth: 500,
									theme: 'tooltipster-light'
								});
							},
							eventAfterAllRender: function(view, element) {
								$('.fCalCheckbox').each(function() {
									var data = $(this).data('full-calendar');
									if (this.checked) {
										$('.fcal-' + data).css('display', '');
									} else {
										$('.fcal-' + data).css('display', 'none');
									}
								});
							}
						});

						$('.fCalCheckbox').on('change', function() {
							var data = $(this).data('full-calendar');
							if (this.checked) {
								$('.fcal-' + data).css('display', '');
							} else {
								$('.fcal-' + data).css('display', 'none');
							}
						});

						$('.gCalDownload').each(function() {
							var textColor = $(this).data('color');
							var calendarId = $(this).data('click');

							$(this).hover(function() {
								$(this).css('color', textColor);
							});

							$(this).tooltip();
							});

						$(window).on('resize', function() {
							if ($(document).width() <= 992) {
								$('##calendar').fullCalendar('option', 'height', 'auto');
							} else {
								$('##calendar').fullCalendar('option', 'height', 'unset');
								$('##calendar').fullCalendar('option', 'aspectRatio', 1.35);
							}
							});

						$('##calendar .fc-left, ##calendar .fc-center, ##calendar .fc-right').addClass('clearfix');

						if ($(document).width() <= 992) {
							$('##calendar').fullCalendar('option', 'height', 'auto');
						} else {
							$('##calendar').fullCalendar('option', 'height', 'unset');
							$('##calendar').fullCalendar('option', 'aspectRatio', 1.35);
						}
					}
				</script>
				<cfif settings.showLegend>
					<fieldset class="fullCalendarLegend">
						<legend>Show/Hide Calendars</legend>
						<cfloop list="#arguments.calendars#" index="i">
							<cfset calendar = calendarService.findWhere({slug=i})>
							<cfif !isNull(calendar)>
								<cfset eventColor = "##3a87ad">
								<cfset eventTextColor = "##ffffff">

								<cfif settings.eventColor neq "">
									<cfset eventColor = settings.eventColor>
								</cfif>

								<cfif !isNull(calendar.getEventColor()) and calendar.getEventColor() neq "">
									<cfset eventColor = calendar.getEventColor()>
								</cfif>

								<cfif settings.eventTextColor neq "">
									<cfset eventTextColor = settings.eventTextColor>
								</cfif>

								<cfif !isNull(calendar.getEventTextColor()) and calendar.getEventTextColor() neq "">
									<cfset eventTextColor = calendar.getEventTextColor()>
								</cfif>

								<div class="fullCalendarLegendItem" style="background-color: #eventColor#; color: #eventTextColor#;">
									<label><input type="checkbox" data-full-calendar="#calendar.getCalendarID()#" class="fCalCheckbox" checked> #calendar.getName()#</label>
									<cfif calendar.getCalendarType() eq "google">
										<a title="Subscribe to this Google Calendar" class="gCalDownload" data-color="#eventTextColor#" data-toggle="tooltip" href="webcal://calendar.google.com/calendar/ical/#calendar.getGoogleCalendarID()#/public/basic.ics" style="color: #eventTextColor#">
											<i class="fa fa-rss"></i>
										</a>
									</cfif>
								</div>
							</cfif>
						</cfloop>
					</fieldset>
				</cfif>
			</cfoutput>
		</cfsavecontent>

		<cfreturn outputString>
	</cffunction>

	<cffunction name="getFullCalendarSettings" returntype="struct" access="private">
		<cfreturn deserializeJSON(settingService.getSetting("fullcalendar"))>
	</cffunction>

</cfcomponent>