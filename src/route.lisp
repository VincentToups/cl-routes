;;;; routes.lisp
;;;;
;;;; This file is part of the cl-routes library, released under Lisp-LGPL.
;;;; See file COPYING for details.
;;;;
;;;; Author: Moskvitin Andrey <archimag@gmail.com>


(in-package #:routes)

;;; route

(defclass route ()
  ((template :initarg :template)))

;;; check-conditions

(defgeneric route-check-conditions (route bindings)
  (:method ((route route) bindings)
    t))

;;; route name

(defgeneric route-name (route)
  (:method ((route route))
    "ROUTE"))

;;; make-route

(defun parse-path (str &optional varspecs)
  (flet ((mkvar (name &optional wildcard)
           (let* ((spec (intern (string-upcase name) :keyword))
                  (parse-fun (getf varspecs spec )))
             (if parse-fun
                 (make-instance (if wildcard
                                    'custom-wildcard-template
                                    'custom-variable-template)
                                :spec spec
                                :parse parse-fun)
                 (make-unify-template (if wildcard
                                          'wildcard
                                          'variable)
                                      spec)))))
    (if (> (length str) 0)
        (if (char= (char str 0)
                   #\*)
            (list (mkvar (intern (string-upcase (subseq str 1)) :keyword) t))
            (let ((pos (position #\: str)))
              (if pos
                  (let ((rest (if (char= (elt str (1+ pos)) #\()
                                  (let ((end (position #\) str :start (1+ pos))))
                                    (if end
                                        (cons (mkvar (subseq str (+ pos 2) end))
                                              (if (< (1+ end) (length str))
                                                  (handler-case
                                                      (parse-path (subseq str (1+ end)))
                                                    (condition () (error "Bad format of the ~S" str)))))
                                        (error "Bad format of the ~S" str)))
                                  (list (mkvar (subseq str (1+ pos)))))))
                    (if (> pos 0)
                        (cons (subseq str 0 pos) rest)
                        rest))
                  (list str))))
        '(""))))

(defun plist->alist (plist)
  (iter (for rest on plist by #'cddr)
        (collect (cons (car rest)
                       (cadr rest)))))

(defun split-template (tmpl)
  (split-sequence #\/ (string-left-trim "/" tmpl)))

(defun parse-template (tmpl &optional varspecs)
  (iter (for path in (split-template (string-left-trim "/" tmpl)))
        (collect (let ((spec (routes::parse-path path varspecs)))
                   (if (cdr spec)
                       (make-unify-template 'concat spec)
                       (car spec))))))

(defun make-route (tmpl &optional varspecs)
  (make-instance 'route
                 :template (parse-template tmpl varspecs)))

;;; route-variables

(defun route-variables (route)
  (template-variables (slot-value route
                                               'template)))

;;; unify/impl for route

(defmethod unify/impl ((b route) (a variable-template) bindings)
  (unify a b bindings))
  
(defmethod unify/impl ((a variable-template) (route route) bindings)
  (if (route-check-conditions route bindings)
      (call-next-method a
                        route
                        bindings)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; generate-url
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun generate-url (route bindings)
  (format nil
          "~{~A~^/~}"
          (apply-bindings (slot-value route 'template)
                          bindings)))
  
