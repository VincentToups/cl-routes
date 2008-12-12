;; routes.asd

(defsystem :routes
  :version "0.1"
  :depends-on (:puri :iterate :split-sequence)
  :components ((:module "unify"
                        :serial t
                        :components ((:file "package")
                                     (:file "unify" :depends-on ("package"))
                                     (:file "merge" :depends-on ("unify"))))
               (:module "routes"
                        :serial t
                        :components ((:file "package")
                                     (:file "route" :depends-on ("package"))
                                     (:file "mapper" :depends-on ("route")))
                        :depends-on ("unify"))))