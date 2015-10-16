angular.module('report', [])
  .controller('ReportBaseCtrl', function ($rootScope, $scope, $state, report, Projects) {
    $rootScope.project = $scope.project;
    $scope.report      = report;
    $scope.archetypes  = $scope.report.archetypes;
    $scope.results     = $scope.report.results;
    $scope.summary     = $scope.report.summary;
    $scope.target      = $scope.summary.target;
    $scope.competitor1 = $scope.summary.competitor1;
    $scope.competitor2 = $scope.summary.competitor2;

    $scope.groups = $scope.results[$scope.project.targetName].map(function(group){
      return group.name;
    });

    $scope.filteredResults = $scope.results.Todos[0];

    $scope.updateResults = function (data) {
      $scope.filteredResults = $scope.results[data.brand][data.group];
      $scope.$broadcast('filterUpdate');
    };

    // Setup for export
    if ($state.current.name.endsWith('.export')) {
      $scope.isExporting = true;

      $scope.onReadyToExport = function (callback) {
        var chartEls;
        var chartCount;

        $scope.$on('chartInit', function(ev, el){
          chartEls = chartEls || $('archetypes-donut-chart');

          if (chartEls.index(el) === chartEls.length - 1) {
            setTimeout(function(){
              $('.wait-splash').hide();
              callback.call();
            }, 500);
          }
        });
      };

      // Brand exists when is a Slimer request to build individual png file.
      // Else shows all to print.
      if ($state.params.brand) {
        $scope.exportingBrandName = $scope.project[$state.params.brand + 'Name'];
        $scope.filteredResults = $scope.results[$scope.exportingBrandName][0];

        for (var k in $scope.summary) {
          var item = $scope.summary[k];

          if ((item !== 'Todos') && (item.status === 'borderline')) {
            $scope.noMatchMessage = item.message;
          }
        }

        if ($state.params.category) {
          $scope.exportingCategory = $scope.filteredResults.categories.find(function(cat){
            return cat.tag === $state.params.category;
          });
        }

        $scope.onReadyToExport(function(){
          $(document).trigger('onReadyToExport');
        });
      } else {
        $scope.isPrintingVersion            = true;
        $scope.exportingBrandName           = $scope.project.targetName;
        $scope.targetResults                = $scope.results[$scope.project.targetName][0];
        $scope.mainChartArchetypesForExport = $scope.targetResults.archetypes;
        $scope.categoriesForPrint           = [];

        [
          $scope.project.targetName,
          $scope.project.competitor1Name,
          $scope.project.competitor2Name
        ].each(function(brandName){
          $scope.results[brandName][0].categories.each(function(category){
            category.brandName = brandName;
            $scope.categoriesForPrint.push(category);
          });
        });

        $scope.onReadyToExport(print);
      }
    }

    $rootScope.shouldDisplayExportActions = function() {
      return $state.current.name.endsWith('.report') && $rootScope.project;
    };

    $rootScope.downloadReportPngUrl = function (project) {
      return Projects.downloadReportPngUrl(project);
    };

    $rootScope.printVersionUrl = function() {
      return $state.href('admin.projects.edit.report.export', {brand: null, category: null});
    };
  })
  .controller('ReportSummaryCtrl', function ($scope) {
    $scope.votes = $scope.report.votes;
  })
  .controller('ReportFilterBarCtrl', function ($scope) {
    $scope.optionsForBrand = [
      {value: 'Todos',                        label: 'Todas as marcas'},
      {value: $scope.project.targetName,      label: $scope.project.targetName},
      {value: $scope.project.competitor1Name, label: $scope.project.competitor1Name},
      {value: $scope.project.competitor2Name, label: $scope.project.competitor2Name}
    ];

    $scope.optionsForGroup = $scope.groups.map(function(group, i) {
      return {value: i, label: group};
    });

    $scope.filterBar = {
      brand: $scope.optionsForBrand[0].value,
      group: $scope.optionsForGroup[0].value
    };

    $scope.filterReport = function() {
      $scope.updateResults($scope.filterBar);
    };
  })
  .controller('ReportImagesCtrl', function ($scope) {
    $scope.imagesResults = $scope.filteredResults.images.filter(function(imgResult){
      return (imgResult.mostChosenVotes !== 0 || imgResult.leastChosenVotes !== 0);
    });
  });
