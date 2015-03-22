var booker = angular.module('booker', ['ui.router']);

booker.service('dataServ', function ($http) {
    this.getData = function (callback) {
        $http.get('https://localhost/booker/').success(callback);
    };
});

booker.factory('calendarFact', function () {
    this.calendar = {
        month: []
    };

    this.calendar.create = function (date) {
        date.setDate(date.getDay() - date.getDay() + 1);

        var offset = (date.getDay() || 7) - 1;
        var week = [];
        var month = date.getMonth();

        for(var i = 0; i < offset; i++) {
            week.push(null);
        }

        for(i = 0; i < 7 - offset; i++) {
            week.push(date.getDate());
        }

        this.month.push(week);

        while(date.getMonth() === month) {
            week = [];

            for(i = 0; i < 7; i++) {
                date.setDate(date.getDate() + 1);

                if(date.getMonth() !== month) {
                    break;
                }

                week.push(date.getDate());
            }

            this.month.push(week);
        }

        date.setDate(date.getDate() - 1);

        offset = 7 - (date.getDay() || 7);

        for(i = 0; i < offset; i++) {
            week.push(null);
        }
    };

    return this.calendar;
});

booker.controller('calendarCtrl', function (dataServ, calendarFact) {
    calendarFact.create(new Date());

    this.month = calendarFact.month;
});