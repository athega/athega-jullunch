$(document).ready(function () {
	'use strict';

	var EVT_SRC_URL = 'http://jullunch.athega.se/register/events',
		evtSource = new EventSource(EVT_SRC_URL),
		$error = $('error'),
		autoshiftTimeout,
		autoshiftEnabled,
		arrivedGuests = 0,
		departedGuests = 0,
		totalGuests = 0,

		showHashAction = function showHashAction() {
			var action = location.hash.slice(1),
				$el = $('#' + action);

			$('.actions').toggleClass('hidden', true);
			$el.toggleClass('hidden', false);

			if ($el.hasClass('autoshift')) {
				autoshiftEnabled = true;
				autoshiftTimeout = setTimeout(function showNextAutoshift() {
					var nextEl = $el.next().hasClass('autoshift') ? $el.next() : $('.autoshift').first();
					itemsHelper(nextEl.attr('id'));
				}, 15000);
			} else {
				clearTimeout(autoshiftTimeout);
				autoshiftEnabled = false;
			}
		},

		itemsHelper = function itemsHelper(itemName, count) {
			var $items = $('#' + itemName + '-items');

			if (autoshiftEnabled) {
				clearTimeout(autoshiftTimeout);
				if (location.hash.slice(1) === itemName) {
					showHashAction();
				} else {
					location.hash = '#' + itemName;
				}
			}

			if (itemName === 'attendance') {
				attendanceHelper();
			} else {
				if (!count) { count = $('#' + itemName + '-count').text(); }
				$('#' + itemName + '-count').text(count);
				$items.empty();
				addItems($items, itemName, count);
			}
		},

		addItems = 	function addItems(items, itemName, count) {
			var li;
			for (var i = 0; i < count; i++) {
				li = $('<li class="' + itemName + '"></li>');
				items.append(li);
				li.addClass('swing-in');
			}
		},

		attendanceHelper = function attendanceHelper() {
			var present = (arrivedGuests-departedGuests) > 0 ? (arrivedGuests-departedGuests) : 0,
				$items = $('#attendance-items');
			$('#attendance-present').text(present);
			$items.empty();
			addItems($items, "arrived", arrivedGuests-present);
			addItems($items, "present", present);
			addItems($items, "invited", totalGuests-departedGuests-arrivedGuests);
		};

	// Initial autoshift data
	$.get('/register/data', function(data) {
		itemsHelper('mulled_wine', data.mulled_wine);
		itemsHelper('food', data.food);
		itemsHelper('drink', data.drink);
		itemsHelper('coffee', data.coffee);

		arrivedGuests = data.arrived;
		departedGuests = data.departed;
		totalGuests = data.rsvped;
		$('#attendance-arrived').text(arrivedGuests);
		$('#attendance-departed').text(departedGuests);
		attendanceHelper();

		showHashAction();
	});

	// Routing
	$(window).on('hashchange', showHashAction);


	// Event source events

	// Arrival
	evtSource.addEventListener("arrival", function(e) {
		var guest = JSON.parse(e.data),
			nameLi = $('<li></li>').text(guest.name);

		$('#arrival-names').prepend(nameLi);
		nameLi.css('opacity', 1).fadeTo(7000, 0, function(){ this.remove(); });

		$('#arrival .arrival-text').css('opacity', 0).fadeTo(1000, 1);
		$('#arrival-name').text(guest.name);
		$('#arrival-company').text(guest.company);

		$('#arrival-photo').removeClass('photo-anim-in');
	}, false);
	evtSource.addEventListener("arrived", function(e) {
		arrivedGuests = e.data;
		$('#arrival-arrived').text(arrivedGuests);
		$('#attendance-arrived').text(arrivedGuests);
	});
	evtSource.addEventListener("arrived-company", function(e) { $('#arrival-arrived-company').text(e.data); });

	// Photo
	evtSource.addEventListener("photo", function(e) {
		var guest = JSON.parse(e.data),
			$photo = $('#arrival-photo');

		$photo.removeClass('photo-anim-in');
		$photo.attr('src', guest.photo.data.img_url);
		window.setTimeout(function() { $photo.addClass('photo-anim-in'); }, 50);
	}, false);

	// Departure
	evtSource.addEventListener("departure", function(e) {
		var guest = JSON.parse(e.data);
		$('#departure-name').text(guest.name);
	}, false);
	evtSource.addEventListener("departed", function(e) {
		departedGuests = e.data;
		var present = (arrivedGuests-departedGuests),
			$items = $('#attendance-items'), li;
		$('#attendance-departed').text(departedGuests);
		$('#attendance-present').text(present >= 0 ? present : 0);
		$items.empty();
		for (var i=0; i<count; i++) {
			li = $('<li class="' + itemName + '"></li>');
			$items.append(li);
			li.addClass('swing-in');
		}

	});

	// Mulled wine, drink, food, coffee (auto shifting)
	evtSource.addEventListener("mulled_wine", function(e) { itemsHelper("mulled_wine", e.data); }, false);
	evtSource.addEventListener("drink", function(e) { itemsHelper("drink", e.data); }, false);
	evtSource.addEventListener("food", function(e) { itemsHelper("food", e.data); }, false);
	evtSource.addEventListener("coffee", function(e) { itemsHelper("coffee", e.data); }, false);

	evtSource.onerror = function() {
		$error.text("Event source failed!");
	};
});
