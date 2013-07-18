Entries = new Meteor.Collection("entries")

moment.lang "de"

if Meteor.is_server
  Meteor.publish 'allEntries', ->
    Entries.find()
    #Entries.find({winner: false})

  #Meteor.startup ->
  Meteor.methods
    resetWinners: ->
      Entries.update({recent: true}, {$set: {recent: false}}, {multi: true})
    resetAll: ->
      Entries.update({winner: true}, {$set: {winner: false}}, {multi: true})
    resetDB: ->
      Entries.remove {}
    removeEntry: (target) ->
      Entries.remove({_id: target})

if Meteor.is_client
  allEntries = Meteor.subscribe 'allEntries'

  Template.raffle.entries = -> Entries.find({}, {sort: {created_at: -1}})


  Template.raffle.loading = ->
    not allEntries.ready()

  Template.raffle.helpers
    gotOne: ->
      Session.get('gotOne')
    gotAny: ->
      findWinner = Entries.findOne(winner: true)
      if findWinner then true else false
    selectedEntry: ->
      entry = Entries.findOne(Session.get('selected_entry'))
      if entry then entry.name else ''
  
  Template.raffle.events =
    'submit #new_entry': (event) ->
      event.preventDefault()
      Entries.insert(name: $('#new_entry_name').val(), winner: false, created_at: moment().format())
      $('#new_entry_name').val('')
    
    'click #draw': ->
      winner = _.shuffle(Entries.find(winner: {$ne: true}).fetch())[0]
      if winner
        Meteor.call 'resetWinners'
        Entries.update(winner._id, $set: {winner: true, recent: true})
        #Session.set('gotOne', true)

    'click #clear': ->
      Meteor.call 'resetAll'
      #Session.set('gotOne', false)

    'click #destroy': ->
      Meteor.call 'resetDB'

    'click .delete_id': ->
      Meteor.call 'removeEntry', this._id

    'click #reset': ->
      Entries.update(Session.get('selected_entry'), $set: {created_at: moment().subtract('m', 5).format()})

  Template.entry.winner_class = ->
    if this.recent then 'success' else 'secondary'

  Template.entry.helpers
    getDate: ->
      if this.created_at then moment(this.created_at).fromNow() else ''

  Template.entry.events
    'click': ->
      Session.set("selected_entry", this._id)

